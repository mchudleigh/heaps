package h3d.col;

import hxd.Debug;
import h3d.col.ExpHull;

// This class represents the "Expanding Polytope Algorithm"
// used to find the closest point to the origin of a convex shape
// known to encompass the origin

class EPA implements h3d.col.ExpHullUser {
	static final THRESH = 0.00001;
	static final MAX_LOOPS = 10000; // Safety constant

	var expHull: ExpHull;

	var col0: ConvexCollider;
	var col1: ConvexCollider;
	var points: Array<Point>;

	var tempFacePoints: Array<Point>;
	var facePoints: Array<Point>;

	// Temporaries
	var sup0:Point = new Point();
	var sup1:Point = new Point();

	static var lastLoops = 0;
	var numLoops = 0;

	public function new(startSimp: Array<Point>, col0: ConvexCollider, col1: ConvexCollider) {
		this.points = startSimp.copy();
		this.col0 = col0;
		this.col1 = col1;
		this.facePoints = [];

		Debug.assert(startSimp.length == 4);

		var startInds = [0,1,2,3];
		// Test that the faces wind correctly
		var p = Plane.fromPoints(points[0], points[1], points[2]);
		p.normalize();
		var p3dist = p.distance(points[3]);
		if (p3dist > 0) {
			// The tetrahedron is wound wrong, flip two points
			startInds = [0,2,1,3];
		}
		expHull = new ExpHull(points, startInds, this);
	}

	public function onDeadFaces(deadFaces: Array<ExpFace>): Void {
		// Do nothing
	}
	public function onNewFaces(newFaces: Array<ExpFace>): Array<NewFaceRes> {
		var ret = [];
		tempFacePoints = [];
		for (i in 0...newFaces.length) {
			// Find the point closest to the origin of this face
			var f = newFaces[i];
			var simp = [points[f.verts[0]], points[f.verts[1]], points[f.verts[2]]];
			var res = HullCollision.dist2D(simp);

			var v = res.point();
			tempFacePoints[i] = v;

			var n = f.getNormal();

			col0.support( n.x,  n.y,  n.z, sup0);
			col1.support(-n.x, -n.y, -n.z, sup1);
			var p = sup0.sub(sup1);
			var pInd = points.length;
			points.push(p);

			var pDist = f.dist(pInd);

			ret.push(new NewFaceRes(v.length(), pInd, pDist < THRESH));
			var res2 = HullCollision.dist2D(simp);
		}

		return ret;
	}
	public function afterAddFaces(newFaces: Array<ExpFace>): Void {
		for (i in 0...newFaces.length) {
			var nf = newFaces[i];
			if (nf.ind >= 0)
				facePoints[nf.ind] = tempFacePoints[i];
		}
	}

	function mainLoop() {
		while(numLoops < MAX_LOOPS) {
			var cont = expHull.iterate();
			if (!cont)
				return;
			numLoops++;
		}
	}
	function getRes():Point {
		var bestFace = expHull.peekNext();
		return facePoints[bestFace.ind];
	}

	public static function getLastLoops() {
		return lastLoops;
	}
	public static function run(startSimp: Array<Point>, col0: ConvexCollider, col1: ConvexCollider):Point {
		var epa = new EPA(startSimp, col0, col1);
		epa.mainLoop();
		lastLoops = epa.numLoops;
		return epa.getRes();
	}
}
