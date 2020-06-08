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
	var hasDegenFace = false;

	public function new(startSimp: Array<Point>, col0: ConvexCollider, col1: ConvexCollider) {
		this.points = startSimp.copy();
		this.col0 = col0;
		this.col1 = col1;
		this.facePoints = [];

		Debug.assert(startSimp.length == 4);

		hasDegenFace = true;
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

			var suspectDegen = false;

			var v = res.point();
			tempFacePoints[i] = v;
			// if (res.simp.length != 3 && v.length() > 0.001) {
			// 	// This triangle does not contain the origin
			// 	// and is "on edge" to the origin so it can not contain the
			// 	// closest point, push a "skip" result
			// 	// Note: this is optional, so the threshold is quite loose
			// 	ret.push(new NewFaceRes(Math.POSITIVE_INFINITY, -1, false, true));
			// 	continue;
			// }

			if(hasDegenFace && v.length() < 0.00000000001) {
				// This is a face that contains the origin
				// replace v with the face's normal and mark this face as
				// possible invalid
				suspectDegen = true;
				var d0 = simp[1].sub(simp[0]);
				var d1 = simp[2].sub(simp[0]);
				v = d0.cross(d1);
				v.normalize();
			}

			col0.support( v.x,  v.y,  v.z, sup0);
			col1.support(-v.x, -v.y, -v.z, sup1);
			var p = sup0.sub(sup1);
			var pInd = points.length;
			points.push(p);

			if (suspectDegen) {
				if (Math.abs(v.dot(p)) < 0.0000001) {
					// This is legitimately a surface face
					ret.push(new NewFaceRes(0, pInd, true, false));
				} else {
					// Not legitimate, push at highest priority
					ret.push(new NewFaceRes(-1, pInd, false, false));
				}
				continue;
			}
			var projV = v.clone();
			projV.normalize();

			// Find the component of p parallel to v
			var vScale = projV.dot(p);
			projV.scale(vScale);

			var pvX = projV.x;
			var pvY = projV.y;
			var pvZ = projV.z;

			var vDiff = v.sub(projV).length();
			ret.push(new NewFaceRes(v.length(), pInd, vDiff < THRESH, false));
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
