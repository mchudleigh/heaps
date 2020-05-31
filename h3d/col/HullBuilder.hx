package h3d.col;

import hds.BinaryHeap;
import hxd.Debug;

class Edge {
	public var p0: Int;
	public var p1: Int;

	public var f: Face;
	public var i: Int;
	public inline function new(f, i) {
		this.f = f; this.i = i;
		this.p0 = f.verts[i];
		this.p1 = f.verts[(i+1)%3];
	}
}

class Face {
	public var verts: Array<Int>;
	public var ownedPoints: Array<Int>;
	public var points: Array<Point>; // Pointer to parent points array
	public var maxDist: Float;
	public var maxPoint: Int;

	// Index into the 'face' array
	public var ind:Int = -1;

	// Face adjacency info
	public var adj: Array<Face>;
	// The "back reference" from the adjacent face
	// ie: how the adjacent faces refers back to this face
	// satisfying "this.adj[i].adj[this.adjRef[i]] == this" for i = 0...3
	public var adjRef: Array<Int>;

	// Has this face been marked dead
	public var dead: Bool;
	public var edges: Array<Edge>;

	public var plane: Plane;

	public function new(verts: Array<Int>, points: Array<Point>) {
		Debug.assert(verts.length == 3);
		Debug.assert(verts[0] != verts[1]);
		Debug.assert(verts[0] != verts[2]);
		Debug.assert(verts[1] != verts[2]);
		this.verts = verts;
		this.points = points;
		this.plane = Plane.fromPoints(
			points[verts[0]],
			points[verts[1]],
			points[verts[2]]);

		this.plane.normalize();
		this.maxDist = Math.NEGATIVE_INFINITY;
		this.maxPoint = -1;

		edges = [
			new Edge(this, 0),
			new Edge(this, 1),
			new Edge(this, 2),
		];
		ownedPoints = [];
		dead = false;
		adj = [];
		adjRef = [];
	}
	public function addPoint(p: Int) {
		ownedPoints.push(p);
		var dist = dist(p);
		if (dist > maxDist) {
			maxDist = dist;
			maxPoint = p;
		}
	}

	public function dist(p: Int) {
		return plane.distance(points[p]);
	}
	public function hasPoints() {
		return this.ownedPoints.length > 0;
	}
	public function getEdge(i: Int) {
		return edges[i];
	}
	public function validate() {
		// Validate adjacency info
		for (i in 0...3) {
			var of = this.adj[i];
			var oe = this.adjRef[i];
			var backFace = of.adj[oe];
			Debug.assert(backFace == this);
		}
		// Check that the adjacent triangles have the same verts/edges
		for (i in 0...3) {
			var v0 = verts[i];
			var v1 = verts[(i+1)%3];
			var ot = adj[i];
			var o0 = ot.verts[adjRef[i]];
			var o1 = ot.verts[(adjRef[i]+1)%3];
			// Should be the same edge, but backwards
			Debug.assert(v0 == o1);
			Debug.assert(v1 == o0);
		}
	}
}

class HullBuilder {

	static final THRESH = 0.0000001;
	var points: Array<Point>;
	var faces: Array<Face>;
	var faceHeap: BinaryHeap;

	var maxFaces: Int;

	public var finalHull: ConvexHull;

	function new(ps: Array<Point>, maxFaces) {
		this.points = ps;
		this.maxFaces = maxFaces;
		faceHeap = new BinaryHeap();

		initialFaces();
		mainLoop();

		makeHull();
	}

	function initialFaces() {
		Debug.assert(points.length > 3);

		// Find 3 points to make the intial faces
		var px = -1; var nx = -1;
		var py = -1; var ny = -1;
		var pz = -1; var nz = -1;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;

		for (pi in 0...points.length) {
			var p = points[pi];
			if (p.x > maxX) { px = pi; maxX = p.x; }
			if (p.y > maxY) { py = pi; maxY = p.y; }
			if (p.z > maxZ) { pz = pi; maxZ = p.z; }

			if (p.x < minX) { nx = pi; minX = p.x; }
			if (p.y < minY) { ny = pi; minY = p.y; }
			if (p.z < minZ) { nz = pi; minZ = p.z; }
		}

		if (px==nx || py == ny || pz == nz) {
			Debug.assert(false, "Degenerate hull");
		}
		var sizeX = maxX-minX;
		var sizeY = maxY-minY;
		var sizeZ = maxZ-minZ;
		var p0, p1;
		if (sizeX > sizeY && sizeX > sizeZ) {
			p0 = px; p1 = nx;
		} else if (sizeY > sizeZ) {
			p0 = py; p1 = ny;
		} else {
			p0 = pz; p1 = nz;
		}
		// From the 2 initial points, find a third
		var diff = points[p0].sub(points[p1]);
		var max = Math.NEGATIVE_INFINITY;
		var p2 = -1;
		for (pi in 0...points.length) {
			var p = points[pi];
			var dist = diff.cross(p).lengthSq();
			if (dist > max && pi != p0 && pi != p1) {
				max = dist;
				p2 = pi;
			}
		}
		if (p2 == -1) {
			Debug.assert(false, "Degenerate hull");
		}

		var f0 = new Face([p0, p1, p2], points);
		var f1 = new Face([p0, p2, p1], points);

		// Manually setup adjacency info
		f0.adj = [f1,f1,f1];
		f0.adjRef = [2,1,0];
		f1.adj = [f0,f0,f0];
		f1.adjRef = [2,1,0];

		f0.validate();
		f1.validate();

		for (pi in 0...points.length) {
			if (pi == p0 || pi == p1 || pi == p2) {
				continue;
			}
			if (f0.dist(pi) > 0) {
				f0.addPoint(pi);
			} else {
				f1.addPoint(pi);
			}
		}
		faces = [];
		addFace(f0);
		addFace(f1);
	}

	function addFace(f: Face) {
		var ind = faceHeap.insert(-f.maxDist);
		f.ind = ind;
		faces[ind] = f;
	}

	function mainLoop() {
		while(true) {
			if (faceHeap.size() >= maxFaces) return;

			var nextInd = faceHeap.peekNext();
			var nextFace = faces[nextInd];

			if (nextFace.maxPoint == -1) {
				// No faces have any points left to process
				return;
			}
			// Otherwise pop the face
			faceHeap.popNext();
			faces[nextInd] = null;
			var currP = nextFace.maxPoint;

			// Get a list of all faces that can "see" the current point
			// and make a connected edge loop around these faces
			var deadFaces = [];
			var edgeLoop = [];
			getEdgeLoopForFace(nextFace, currP, deadFaces, edgeLoop);
			validateConEdgeLoop(edgeLoop);

			var orphanPoints:  Map<Int, Bool> = new Map();

			for (df in deadFaces) {
				faceHeap.remove(df.ind);
				for (p in df.ownedPoints) {
					orphanPoints.set(p, true);
				}
			}

			// Create new faces from the edge loop and current point
			var newFaces = [];
			var lastFace:Face = null;
			for (edge in edgeLoop) {
				var newFace = new Face([edge.p0, edge.p1, currP], points);
				newFaces.push(newFace);
				// Update adjacency

				// Connect across edge
				var of = edge.f.adj[edge.i];
				Debug.assert(of.dead == false);
				var oe = edge.f.adjRef[edge.i];

				of.adj[oe] = newFace;
				newFace.adj[0] = of;

				newFace.adjRef[0] = oe;
				of.adjRef[oe] = 0;

				// Connect backwards
				if (lastFace != null) {
					lastFace.adj[1] = newFace;
					newFace.adj[2] = lastFace;
				}
				newFace.adjRef[1] = 2; newFace.adjRef[2] = 1;

				lastFace = newFace;
			}
			// Finally close the face loop
			newFaces[0].adj[2] = lastFace;
			lastFace.adj[1] = newFaces[0];
			for (i in 0...newFaces.length) {
				var face = newFaces[i];
				face.validate();
			}

			// Add the orphaned points to the face
			// they are most orthogonally distant to
			for (p => _ in orphanPoints) {
				if (p == currP) continue;
				var bestDist = Math.NEGATIVE_INFINITY;
				var bestFace = null;
				for (f in newFaces) {
					var dist = f.dist(p);
					if (dist > THRESH) {
						bestDist = dist;
						bestFace = f;
					}
				}
				if (bestFace != null) {
					bestFace.addPoint(p);
				}
				// If none of the new faces can "see" this point, it's
				// interior and silently dropped
			}

			// Finally add the new faces to the face list
			for (f in newFaces) {
				addFace(f);
			}
		}
	}

	function makeHull() {
		// Take the final list of faces from the main loop and make a hull
		var faceInds = [];
		for (fInd in faceHeap) {
			var f = faces[fInd];

			faceInds.push(f.verts[0]);
			faceInds.push(f.verts[1]);
			faceInds.push(f.verts[2]);
		}
		var vects = [];
		for (p in points) {
			vects.push(p.toVector());
		}
		finalHull = new ConvexHull(vects, faceInds);
	}

	// Perform a search of all connected faces that can "see"
	// the given point. Outputs the list of faces and edge loop
	function getEdgeLoopForFace(face: Face, point: Int,
		deadFacesOut:Array<Face>, edgeLoopOut:Array<Edge>) {
		var faceStack = [face, face, face];
		var edgeStack = [2,1,0];

		face.dead = true;
		deadFacesOut.push(face);
		while(faceStack.length != 0) {
			Debug.assert(faceStack.length == edgeStack.length);
			var f = faceStack.pop();
			var e = edgeStack.pop();
			var of = f.adj[e];
			var oe = f.adjRef[e];

			// Gratuitous sanity check
			Debug.assert(of.adj[oe] == f);

			if (of.dead) continue; // Looped back around to a previous face

			var dist = of.dist(point);
			if (dist > -THRESH) {
				// This face can see the point, mark it
				// as dead and push it's two remaining
				// edges onto the stack
				of.dead = true;
				deadFacesOut.push(of);

				faceStack.push(of);
				edgeStack.push((oe+2)%3);

				faceStack.push(of);
				edgeStack.push((oe+1)%3);
			} else {
				// The other face is not visible, therefore this edge is
				// part of the loop
				edgeLoopOut.push(f.getEdge(e));
			}
		}
	}

	// Validate an edge loop that is in loop order
	function validateConEdgeLoop(edgeLoop: Array<Edge>) {
		var startPt = edgeLoop[0].p0;
		var currPt = startPt;
		var seenPts: Map<Int,Bool> = new Map();
		for (e in edgeLoop) {
			// Check connected
			Debug.assert(e.p0 == currPt);
			currPt = e.p1;

			// Detect loops
			Debug.assert(seenPts[currPt] == null);
			seenPts[currPt] = true;
		}
		// Check closed
		Debug.assert(currPt == startPt);
	}

	public static function buildHull(points: Array<Point>, maxFaces = 100) : ConvexHull {

		// TODO: find a reasonable limit, taking hash collision into account
		//Debug.assert(points.length < 10000);
		var builder = new HullBuilder(points, maxFaces);

		return builder.finalHull;
	}

	public static function makeTestCube(): ConvexHull {
		var cubePoints = [
			new Point( 1, 1, 1),
			new Point(-1, 1, 1),
			new Point( 1,-1, 1),
			new Point(-1,-1, 1),

			new Point( 1, 1,-1),
			new Point(-1, 1,-1),
			new Point( 1,-1,-1),
			new Point(-1,-1,-1),
		];

		return buildHull(cubePoints);
	}
}
