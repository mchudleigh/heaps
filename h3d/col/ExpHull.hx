package h3d.col;

import hxd.Debug;
import hds.BinaryHeap;

// This class encapsulates the common core between
// the QuickHull hull building algorithm
// and the EPA collision penetration algorithm
// The weird user facing interface is due to the differences
// between those two algorithms

class ExpEdge {
	public var p0: Int;
	public var p1: Int;

	public var f: ExpFace;
	public var i: Int;
	public inline function new(f, i) {
		this.f = f; this.i = i;
		this.p0 = f.verts[i];
		this.p1 = f.verts[(i+1)%3];
	}
}

class ExpFace {
	public var verts: Array<Int>;
	public var points: Array<Point>; // Pointer to global points array
	public var termFlag: Bool;
	public var priority: Float;

	// Index into the 'face' array
	public var ind:Int = -1;

	// Face adjacency info
	public var adj: Array<ExpFace>;
	// The "back reference" from the adjacent face
	// ie: how the adjacent faces refers back to this face
	// satisfying "this.adj[i].adj[this.adjRef[i]] == this" for i = 0...3
	public var adjRef: Array<Int>;

	// Has this face been marked dead
	public var dead: Bool;
	public var edges: Array<ExpEdge>;

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

		edges = [
			new ExpEdge(this, 0),
			new ExpEdge(this, 1),
			new ExpEdge(this, 2),
		];
		dead = false;
		adj = [];
		adjRef = [];
	}

	public function dist(p: Int) {
		return plane.distance(points[p]);
	}

	public function terminate() {
		return this.termFlag;
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

class NewFaceRes {
	public var priority: Float;
	public var term: Bool;
	public function new(pri, term) {
		this.priority = pri;
		this.term = term;
	}
}

interface ExpHullUser {
	public function onDeadFaces(deadFaces: Array<ExpFace>): Void;
	public function onNewFaces(deadFaces: Array<ExpFace>): Array<NewFaceRes>;
	public function afterAddFaces(deadFaces: Array<ExpFace>): Void;
	public function getPoint(face:ExpFace):Int;
}


class ExpHull {
	static final THRESH = 0.0000001;

	public var faceHeap: BinaryHeap;
	public var faces: Array<ExpFace>;
	public var points: Array<Point>;

	var user: ExpHullUser;

	var done = false;

	public function new(points: Array<Point>, initPoints: Array<Int>,
		hullUser: ExpHullUser) {
		this.faceHeap = new BinaryHeap();
		this.faces = [];
		this.points = points;
		this.user = hullUser;

		Debug.assert(initPoints.length == 3);
		initTriangles(initPoints);
		//TODO: 4 point tetrahedra
	}

	// Create 2 opposing triangles from 3 points
	function initTriangles(initPoints: Array<Int>) {
		var p0 = initPoints[0];
		var p1 = initPoints[1];
		var p2 = initPoints[2];
		var f0 = new ExpFace([p0, p1, p2], points);
		var f1 = new ExpFace([p0, p2, p1], points);

		// Manually setup adjacency info
		f0.adj = [f1,f1,f1];
		f0.adjRef = [2,1,0];
		f1.adj = [f0,f0,f0];
		f1.adjRef = [2,1,0];

		f0.validate();
		f1.validate();

		var faceRes = user.onNewFaces([f0,f1]);

		Debug.assert(faceRes.length == 2);
		insertFace(f0, faceRes[0]);
		insertFace(f1, faceRes[1]);

		user.afterAddFaces([f0,f1]);
	}
	function insertFace(f:ExpFace, fr: NewFaceRes) {
		f.termFlag = fr.term;
		f.priority = fr.priority;

		f.ind = faceHeap.insert(fr.priority);
		faces[f.ind] = f;
	}

	// Pop a single face off the heap and expand the hull
	// will call both callbacks once
	// Returns "true" if there is more to process (ie: false on termination)
	public function iterate(): Bool {
		if (done)
			return false;

		var nextInd = faceHeap.peekNext();
		var nextFace = faces[nextInd];

		if (nextFace.termFlag) {
			// Termination condition
			done = true;
			return false;
		}

		// Otherwise pop the face
		faceHeap.popNext();
		faces[nextInd] = null;
		var currP = user.getPoint(nextFace);

		var deadFaces = [];
		var edgeLoop = [];
		getEdgeLoopForFace(nextFace, currP, deadFaces, edgeLoop);
		validateEdgeLoop(edgeLoop);

		user.onDeadFaces(deadFaces);

		for (df in deadFaces) {
			if (df != nextFace) faceHeap.remove(df.ind);
		}

		// Create new faces from the edge loop and current point
		var newFaces:Array<ExpFace> = [];
		var lastFace:ExpFace = null;

		for (edge in edgeLoop) {
			var newFace = new ExpFace([edge.p0, edge.p1, currP], points);
			newFaces.push(newFace);
			// Update adjacency

			// Connect across edge
			var of = edge.f.adj[edge.i];
			Debug.assert(of.dead == false);
			var oe = edge.f.adjRef[edge.i];

			of.adj[oe] = newFace;
			of.adjRef[oe] = 0;

			newFace.adj[0] = of;
			newFace.adjRef[0] = oe;

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

		// Call the new face callback
		var faceRes = user.onNewFaces(newFaces);

		// Insert the faces
		Debug.assert(faceRes.length == newFaces.length);
		for (i in 0...newFaces.length) {
			insertFace(newFaces[i], faceRes[i]);
		}
		user.afterAddFaces(newFaces);
		return true;
	}
	// Perform a search of all connected faces that can "see"
	// the given point. Outputs the list of faces and edge loop
	function getEdgeLoopForFace(face: ExpFace, point: Int,
		deadFacesOut:Array<ExpFace>, edgeLoopOut:Array<ExpEdge>) {
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
	function validateEdgeLoop(edgeLoop: Array<ExpEdge>) {
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

}
