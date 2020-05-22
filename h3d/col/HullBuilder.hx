package h3d.col;

import hxd.Debug;

class Edge {
	public var p0: Int;
	public var p1: Int;
	public inline function new(p0, p1) {
		this.p0 = p0; this.p1 = p1;
	}
}

class Face {
	public var verts: Array<Int>;
	public var ownedPoints: Array<Int>;
	public var points: Array<Point>; // Pointer to parent points array
	public var maxDist: Float;
	public var maxPoint: Int;

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
			new Edge(verts[0], verts[1]),
			new Edge(verts[1], verts[2]),
			new Edge(verts[2], verts[0])
		];
		ownedPoints = [];
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
}

class HullBuilder {

	static final THRESH = 0.0000001;
	var points: Array<Point>;
	var faces: Array<Face>;

	var maxFaces: Int;

	public var finalHull: ConvexHull;

	function new(ps: Array<Point>, maxFaces) {
		this.points = ps;
		this.maxFaces = maxFaces;

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
		faces = [f0, f1];
	}

	function mainLoop() {
		while(true) {
			if (faces.length >= maxFaces) return;

			var bestFace: Face = null;
			var bestDist = Math.NEGATIVE_INFINITY;
			for (f in faces) {
				if (f.hasPoints()) {
					if (f.maxDist > bestDist) {
						bestDist = f.maxDist;
						bestFace = f;
					}
				}
			}
			if (bestFace == null) return; // All points accounted for

			var currP = bestFace.maxPoint;

			// Find all faces that can "see" this point and remove them
			var deadFaces = [];
			var orphanPoints:  Map<Int, Bool> = new Map();
			for (f in faces) {
				var dist = f.dist(currP);
				if (dist > -THRESH) {
					// This face should be removed
					for (p in f.ownedPoints) {
						orphanPoints.set(p, true);
					}
					deadFaces.push(f);
				}
			}
			for (df in deadFaces) {
				faces.remove(df);
			}

			// Find the edge loop of dead faces
			var edgeLoop = facesToEdgeLoop(deadFaces);
			// Check that the edge loop is indeed a single loop (optional)
			validateEdgeLoop(edgeLoop);

			// Create new faces from the edge loop and current point
			var newFaces = [];
			for (edge in edgeLoop) {
				var newFace = new Face([currP, edge.p0, edge.p1], points);
				newFaces.push(newFace);
			}

			// Add the orphaned points to the face
			// they are most orthogonal to
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
				faces.push(f);
			}
		}
	}

	function makeHull() {
		// Take the final list of faces from the main loop and make a hull
		var faceInds = [];
		for (f in faces) {
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

	function facesToEdgeLoop(faces: Array<Face>) : Array<Edge> {
		// Iterate all dead face edges, adding them to a map
		// but removing edges that are traversed backwards
		var edges: Map<Int, Edge> = [];
		for (f in faces) {
			for (ei in 0...3) {
				var edge = f.getEdge(ei);
				// Add all the edges
				var fwdKey = edge.p0+edge.p1*points.length;
				edges[fwdKey] = edge;
			}
		}
		for (f in faces) {
			for (ei in 0...3) {
				var edge = f.getEdge(ei);
				// Now find all the edges we back over and remove them
				var revKey = edge.p1+edge.p0*points.length;
				if (edges.exists(revKey)) {
					edges.remove(revKey);
				}
			}
		}
		var ret = [];
		for (_=> e in edges) {
			if (e != null)
				ret.push(e);
		}
		return ret;
	}

	function validateEdgeLoop(edgeLoop: Array<Edge>) {

		var startPt = edgeLoop[0].p0;
		var currPt = startPt;
		var nextPt = -1;
		var edgeCount = 0;
		while(edgeCount < edgeLoop.length) {
			// Find the edge starting at the current pt (and make sure its only 1)
			var foundEdges = 0;
			var nextPt = -1;
			for (e in edgeLoop) {
				if (e.p0 == currPt) {
					nextPt = e.p1;
					foundEdges++;
				}
			}
			// Make sure their is no branching
			Debug.assert(foundEdges == 1);
			// Make sure we have not returned to the start too soon
			Debug.assert(edgeCount == 0 || currPt != startPt);
			currPt = nextPt;
			edgeCount++;
		}
		// Ensure we return to the start at the correct time
		Debug.assert(currPt == startPt);
	}

	public static function buildHull(points: Array<Point>, maxFaces = 100) : ConvexHull {

		// We can't accept more than roughly ten thousand points for algorithmic
		// correctness and general sanity
		Debug.assert(points.length < 10000);
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
