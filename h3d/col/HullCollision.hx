package h3d.col;

import h3d.scene.fwd.PointLight;
import hxd.Debug;

import h3d.col.Point;

// An implementation of GJK enhanced with the signed volume distance method
// based on this paper by Montanari, Petrinic and Barbier:
// https://ora.ox.ac.uk/objects/uuid:69c743d9-73de-4aff-8e6f-b4dd7c010907/download_file?safe_filename=GJK.PDF&file_format=application%2Fpdf&type_of_work=Journal+article


// Simple tuple like class to contain results from the dist*D functions
class DistRes {
	public var simp: Array<HullColPoint>;
	public var barCoords: Array<Float>;
	public inline function new(s: Array<HullColPoint>, b: Array<Float>) {
		simp = s;
		barCoords = b;
	}
	public function point(): HullColPoint {
		var resA = new Point();
		var resB = new Point();
		var resPoint = new Point();
		for (i in 0...simp.length) {
			resA = resA.add(simp[i].srcA.multiply(barCoords[i]));
			resB = resB.add(simp[i].srcB.multiply(barCoords[i]));
			resPoint = resPoint.add(simp[i].point.multiply(barCoords[i]));
		}
		var ret = new HullColPoint(resA, resB);
		Debug.assert(Debug.floatNear(ret.point.x, resPoint.x));
		Debug.assert(Debug.floatNear(ret.point.y, resPoint.y));
		Debug.assert(Debug.floatNear(ret.point.z, resPoint.z));
		return ret;
	}
}

class CachedColRes {
	public var p0: Point;
	public var p1: Point;
	public var id0: Int;
	public var id1: Int;
}

class ColRes {
	public var collides: Bool;
	// vec is the distance/penetration vector
	public var vec: Point;
	// point is the closest point to the origin of the Minkowski hull
	// or the penetration vector if collision
	public var point: Null<HullColPoint>;
	public function new(c,v,p) {
		collides = c;
		vec = v;
		point = p;
	}
}

class HullCollision {
	static final  MAX_LOOP = 1000;
	static final REL = 0.01;

	var loopCount: Int;
	var cache: Map<Int, CachedColRes>;
	public function new() {
		cache = new Map();
	}

	function getCachedRes(id0, id1): CachedColRes {
		// TODO
		return null;
	}

	public function getLastLoopCount() {
		return loopCount;
	}

	public function testCollision(c0:ConvexCollider, c1:ConvexCollider, precise:Bool, tol = 0.0000001): ColRes {
		// Check the cache for a start point
		var s0; var s1;
		var cached = getCachedRes(c0.getID(), c1.getID());
		if (cached != null) {
			s0 = cached.p0;
			s1 = cached.p1;
		} else {
			s0 = c0.startPoint();
			s1 = c1.startPoint();
		}

		var hcV = new HullColPoint(s0, s1); // Point in simplex closest to origin. Updated every iteration
		var v = hcV.point;
		var simp: Array<HullColPoint> = [];
		var sup0 = new Point();
		var sup1 = new Point();
		var vLenSq = 0.0;
		var maxSimpLnSq = 0.0;
		loopCount = 0;
		var p: HullColPoint = null;
		var pDotV = 0.0;
		var vLenMinPDotV = 0.0;
		var relSqVLenSq = 0.0;
		var vDiffAccum = 0.0; // A low-pass accumulator of the v difference
		var vDiff = new Point();
		while(loopCount < MAX_LOOP) {
			c0.support(-v.x, -v.y, -v.z, sup0);
			c1.support( v.x,  v.y,  v.z, sup1);

			p = new HullColPoint(sup0, sup1);

			vLenSq = v.lengthSq();

			pDotV = p.point.dot(v);
			if (!precise && pDotV > 1000*tol) {
				// Fast, but imprecise no-collision condition
				return new ColRes(false, v, hcV);
			}
			vLenMinPDotV = vLenSq-pDotV;
			relSqVLenSq = REL*REL*vLenSq;
			if (	vLenSq > 0.000000001 &&
					vLenMinPDotV < relSqVLenSq) {
				// More precise no-collision condition
				return new ColRes(false, v, hcV);
			}
			// Check if p is already in the simplex
			for (sp in simp) {
				var d = p.point.sub(sp.point).length();
				if (vLenSq > 0.000000001 && d < tol) {
					// This point is in the simplex
					return new ColRes(false, v, hcV);
				}
			}

			simp.push(p);
			// Refine the simplex
			var distRes = dist(simp);
			simp = distRes.simp;

			if (simp.length == 4) {
				// Origin is contained, therefore contact
				break;
			}
			maxSimpLnSq = 0.0;
			for (sp in simp) {
				maxSimpLnSq = Math.max(maxSimpLnSq, sp.point.lengthSq());
			}
			if (vLenSq < tol*maxSimpLnSq) {
				// point V is _really_ close to the origin (relative to
				// the size of the simplex, consider this a grazing collision)
				break;
			}
			var lastV = v;
			hcV = distRes.point();
			v = hcV.point;
			vDiff.setSub(lastV, v);
			vDiffAccum = vDiff.lengthSq() + vDiffAccum * 0.5;
			if (vDiffAccum < tol){
				// This has settled without triggering the other
				// termination conditions
				return new ColRes(false, v, hcV);
			}

			loopCount++;
		}

		if (!precise) {
			return new ColRes(true, v, hcV); // Don't run EPA, assume V is good enough
		}
		// Collision, run EPA to find the penetration vector

		// Debug vars
		// var gjkSimp = [];
		// for (s in simp) {
		// 	gjkSimp.push(s.clone());
		// }
		// var gjkPoints = simp.length;
		// var gjkRes = dist(gjkSimp);
		// var gjkP = gjkRes.point();

		if (loopCount == MAX_LOOP) {
			return new ColRes(false, v, hcV);
		}

		if (simp.length == 1) {
			return new ColRes(true, v, hcV);
		}

		// Add support points until the simplex has 4 points
		// The goal is not to get closer to the origin, but rather full enclose
		// the origin (the bigger the better) being on a face or edge is fine
		var simpLoopCount = 0;
		while(simp.length != 4) {
			if (simpLoopCount++ > 5) break;
			switch (simp.length) {
				case 2: {
					// Get support points from the 4 normal dirs to the edge
					var dir = simp[1].point.sub(simp[0].point);
					if (dir.length() < tol) {
						// It's basically the same point, call it a collision
						return new ColRes(true, simp[0].point, simp[0]);
					}
					var t = new Point(1,1,1);
					var n0 = dir.cross(t);
					if (n0.lengthSq() < 0.000001) {
						// Accidentally parallel, try again
						t.y = -1;
						n0 = dir.cross(t);
					}
					n0.normalize();
					var n1 = dir.cross(n0);
					n1.normalize();

					c0.support( n0.x, n0.y, n0.z, sup0);
					c1.support(-n0.x,-n0.y,-n0.z, sup1);
					var p0 = new HullColPoint(sup0, sup1);
					c0.support(-n0.x,-n0.y,-n0.z, sup0);
					c1.support( n0.x, n0.y, n0.z, sup1);
					var p1 = new HullColPoint(sup0, sup1);

					c0.support( n1.x, n1.y, n1.z, sup0);
					c1.support(-n1.x,-n1.y,-n1.z, sup1);
					var p2 = new HullColPoint(sup0, sup1);
					c0.support(-n1.x,-n1.y,-n1.z, sup0);
					c1.support( n1.x, n1.y, n1.z, sup1);
					var p3 = new HullColPoint(sup0, sup1);

					var p0DotN = p0.point.dot(n0);
					var p1DotN = p1.point.dot(n0) * -1.0;
					var p2DotN = p2.point.dot(n1);
					var p3DotN = p3.point.dot(n1) * -1.0;
					// Otherwise add the furthest point and loop
					if (p0DotN > p1DotN && p0DotN > p2DotN && p0DotN > p3DotN)
						simp.push(p0);
					else if (p1DotN > p2DotN && p1DotN > p3DotN)
						simp.push(p1);
					else if (p2DotN > p3DotN)
						simp.push(p2);
					else
						simp.push(p3);
				}
				case 3: {
					// project a ray in both normals to the simplex
					// keep the point furthest out
					var v0 = simp[1].point.sub(simp[0].point);
					var v1 = simp[2].point.sub(simp[0].point);
					var n = v0.cross(v1);
					if (n.lengthSq() < 0.0000000001) {
						// Colinear, drop a point and return to the 2-simplex case

						// This should be very unlikely though
						simp.pop();
						continue;
					}
					n.normalize();
					c0.support( n.x, n.y, n.z, sup0);
					c1.support(-n.x,-n.y,-n.z, sup1);
					var p0 = new HullColPoint(sup0, sup1);

					c0.support(-n.x,-n.y,-n.z, sup0);
					c1.support( n.x, n.y, n.z, sup1);
					var p1 = new HullColPoint(sup0, sup1);

					// Include the point that contains the origin the best
					var posN = simp[0].point.dot(n);
					simp.push((posN > 0) ? p1: p0);
				}
				default: throw "impossible";
			}
		}
		var dRes = dist(simp);

		try {
			var penVect = EPA.run(simp, c0, c1);
			loopCount += EPA.getLastLoops();
			return new ColRes(true, penVect.point, penVect);
		} catch(err:Dynamic) {
			// Treat as a glancing collision
			return new ColRes(true, new Point(0,0,0), null);
		}
	}

	// Sign comparison that intentionally fails for 0 and NaN
	static inline function compSigns(v0:Float, v1:Float) {
		return ((v0>0 && v1>0.00000001) || (v0<0 && v1<-0.00000001));
	}

	static function dist(simp:Array<HullColPoint>): DistRes {
		switch(simp.length) {
			case 4: return dist3D(simp);
			case 3: return dist2D(simp);
			case 2: return dist1D(simp);
			case 1: return new DistRes(simp, [1]);
			default: throw "bad simplex";
		}
	}


	// Equivalent to S3D in the paper
	static function dist3D( simp: Array<HullColPoint>): DistRes {
		Debug.assert(simp.length == 4);
		var p0 = simp[0].point;
		var p1 = simp[1].point;
		var p2 = simp[2].point;
		var p3 = simp[3].point;

		// Find the 4 cofactors
		// IE: the volume of the 4 tetrahedra with one point replaced by the origin

		var c0 =    (p1.z*(p2.x*p3.y-p2.y*p3.x) - p2.z*(p1.x*p3.y-p1.y*p3.x) + p3.z*(p1.x*p2.y-p1.y*p2.x));
		var c1 = -1*(p0.z*(p2.x*p3.y-p2.y*p3.x) - p2.z*(p0.x*p3.y-p0.y*p3.x) + p3.z*(p0.x*p2.y-p0.y*p2.x));
		var c2 =    (p0.z*(p1.x*p3.y-p1.y*p3.x) - p1.z*(p0.x*p3.y-p0.y*p3.x) + p3.z*(p0.x*p1.y-p0.y*p1.x));
		var c3 = -1*(p0.z*(p1.x*p2.y-p1.y*p2.x) - p1.z*(p0.x*p2.y-p0.y*p2.x) + p2.z*(p0.x*p1.y-p0.y*p1.x));

		var vol = c0+c1+c2+c3;
		if (compSigns(c0,vol) && compSigns(c1,vol) && compSigns(c2,vol) && compSigns(c3,vol)) {
			// The origin is inside the simplex
			return new DistRes(simp, [c0/vol, c1/vol, c2/vol, c3/vol]);
		}
		// Otherwise test sub-simplices
		var subRets = [];
		var bestRet = -1;
		var bestDist = Math.POSITIVE_INFINITY;
		var cs = [c0, c1, c2, c3];
		for (i in 0...4) {
			// Note: compSigns will not return true if total volume is 0
			// forcing comparison of all sub-simplices
			if (compSigns(cs[i], vol)) continue;
			var subSimp = switch(i) {
				case 0: [simp[1], simp[2], simp[3]];
				case 1: [simp[0], simp[2], simp[3]];
				case 2: [simp[0], simp[1], simp[3]];
				case 3: [simp[0], simp[1], simp[2]];
				default: throw "Impossible";
			}
			var subRet = dist2D(subSimp);
			var d = subRet.point().point.lengthSq();
			if (d < bestDist) {
				bestDist = d;
				bestRet = i;
				subRets[i] = subRet;
			}
		}
		return subRets[bestRet];
	}

	// Equivalent to S2D in the paper
	// Note: this is public because it's used by EPA
	public static function dist2D( simp: Array<HullColPoint>): DistRes {
		Debug.assert(simp.length == 3);
		var p0 = simp[0].point;
		var p1 = simp[1].point;
		var p2 = simp[2].point;
		var n = (p1.sub(p0)).cross(p2.sub(p0));
		n.normalize();
		var pOrig = n.multiply(p0.dot(n));

		// Find the areas of the triangles projected onto basic axis
		var sX = p1.y*p2.z + p0.y*p1.z + p2.y*p0.z - p1.y*p0.z - p2.y*p1.z - p0.y*p2.z;
		var sY = p1.z*p2.x + p0.z*p1.x + p2.z*p0.x - p1.z*p0.x - p2.z*p1.x - p0.z*p2.x;
		var sZ = p1.x*p2.y + p0.x*p1.y + p2.x*p0.y - p1.x*p0.y - p2.x*p1.y - p0.x*p2.y;
		var magX = Math.abs(sX);
		var magY = Math.abs(sY);
		var magZ = Math.abs(sZ);
		var p0x, p0y;
		var p1x, p1y;
		var p2x, p2y;
		var pOx, pOy;
		var area;
		// Project onto "biggest" 2D triangle
		if (magX > magY && magX > magZ) {
			p0x = p0.y; p0y = p0.z;
			p1x = p1.y; p1y = p1.z;
			p2x = p2.y; p2y = p2.z;
			pOx = pOrig.y; pOy = pOrig.z;
			area = sX;
		} else if (magY > magZ) {
			p0x = p0.z; p0y = p0.x;
			p1x = p1.z; p1y = p1.x;
			p2x = p2.z; p2y = p2.x;
			pOx = pOrig.z; pOy = pOrig.x;
			area = sY;
		} else {
			p0x = p0.x; p0y = p0.y;
			p1x = p1.x; p1y = p1.y;
			p2x = p2.x; p2y = p2.y;
			pOx = pOrig.x; pOy = pOrig.y;
			area = sZ;
		}

		// Calc cofactors by replacing points with the projected origin
		var c0 = p1x*p2y + pOx*p1y + p2x*pOy - p1x*pOy - p2x*p1y - pOx*p2y;
		var c1 = pOx*p2y + p0x*pOy + p2x*p0y - pOx*p0y - p2x*pOy - p0x*p2y;
		var c2 = p1x*pOy + p0x*p1y + pOx*p0y - p1x*p0y - pOx*p1y - p0x*pOy;

		// var cSum = c0+c1+c2;
		// var sumDiff = cSum-area;
		// Debug.assert(Math.abs(sumDiff) < 0.00001);

		if(compSigns(c0, area) && compSigns(c1, area) && compSigns(c2, area)) {
			// Inside the simplex
			return new DistRes(simp, [c0/area, c1/area, c2/area]);
		}
		// Otherwise check the sub simplices
		var subRets = [];
		var bestRet = -1;
		var bestDist = Math.POSITIVE_INFINITY;
		var cs = [c0, c1, c2];
		for (i in 0...3) {
			// Note: compSigns will not return true if any face is degenerate
			// forcing comparison of all sub-simplices
			if (compSigns(cs[i], area)) continue;
			var subSimp = switch(i) {
				case 0: [simp[1], simp[2]];
				case 1: [simp[0], simp[2]];
				case 2: [simp[0], simp[1]];
				default: throw "Impossible";
			}
			var subRet = dist1D(subSimp);
			var d = subRet.point().point.lengthSq();
			if (d < bestDist) {
				bestDist = d;
				bestRet = i;
				subRets[i] = subRet;
			}
		}
		return subRets[bestRet];
	}

	// Equivalent to S1D in the paper
	static function dist1D( simp: Array<HullColPoint>): DistRes {
		Debug.assert(simp.length == 2);
		var p0 = simp[0].point;
		var p1 = simp[1].point;
		var dir = p0.sub(p1);
		dir.normalize();
		var projOrig = dir.multiply(p1.dot(dir));
		projOrig = p1.sub(projOrig);

		// Project onto best axis
		var sX = p0.x-p1.x;
		var sY = p0.y-p1.y;
		var sZ = p0.z-p1.z;
		var magX = Math.abs(sX); var magY = Math.abs(sY); var magZ = Math.abs(sZ);
		var pr0, pr1, prO, len;
		if (magX > magY && magX > magZ) {
			pr0 = p0.x; pr1 = p1.x; prO = projOrig.x; len = sX;
		} else if (magY > magZ) {
			pr0 = p0.y; pr1 = p1.y; prO = projOrig.y; len = sY;
		} else {
			pr0 = p0.z; pr1 = p1.z; prO = projOrig.z; len = sZ;
		}
		var c0 = (prO - pr1);
		var c1 = (pr0 - prO);
		if (compSigns(c0, len) && compSigns(c1, len)) {
			return new DistRes(simp, [c0/len, c1/len]);
		} else {
			// Return the closest point
			var p = (p0.lengthSq() <= p1.lengthSq()) ? simp[0]:simp[1];
			return new DistRes([p], [1]);
		}
	}
}
