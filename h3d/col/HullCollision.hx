package h3d.col;

import hxd.Debug;

import h3d.col.Point;

// An implementation of GJK enhanced with the signed volume distance method
// based on this paper by Montanari, Petrinic and Barbier:
// https://ora.ox.ac.uk/objects/uuid:69c743d9-73de-4aff-8e6f-b4dd7c010907/download_file?safe_filename=GJK.PDF&file_format=application%2Fpdf&type_of_work=Journal+article

interface ConvexCollider {
	public function getID():Int;
	public function support(x:Float,y:Float,z:Float, out:Point):Void;
	public function startPoint(): Point;
}

class SphereCollider implements ConvexCollider {
	public var center: Point;
	public var radius: Float;
	public var id: Int;
	public function new(c, r, i) {
		center = c;
		radius = r;
		id = i;
	}
	public function getID() { return id;}

	public function support(x:Float, y:Float, z:Float, out:Point) {
		out.x = x; out.y = y; out.z = z;
		out.normalize();
		out.scale(radius);
		// Add, but avoid allocation
		out.x += center.x;
		out.y += center.y;
		out.z += center.z;
	}
	public function startPoint():Point {
		return center;
	}
}


// Simple tuple like class to contain results from the dist*D functions
class DistRes {
	public var simp: Array<Point>;
	public var barCoords: Array<Float>;
	public inline function new(s: Array<Point>, b: Array<Float>) {
		simp = s;
		barCoords = b;
	}
	public function point(): Point {
		var ret = new Point();
		for (i in 0...simp.length) {
			ret = ret.add(simp[i].multiply(barCoords[i]));
		}
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
	// Vec is the distance vector if no collision
	// or the penetration vector if collision
	public var vec: Point;
	public function new(c,v) {
		collides = c;
		vec = v;
	}
}

class HullCollision {
	static final  MAX_LOOP = 1000;
	static final REL = 0.1;

	var cache: Map<Int, CachedColRes>;
	public function new() {
		cache = new Map();
	}

	function getCachedRes(id0, id1): CachedColRes {
		// TODO
		return null;
	}

	public function testCollision(c0:ConvexCollider, c1:ConvexCollider, precise:Bool, tol = 0.000001): ColRes {
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

		var v = s0.sub(s1); // Point in simplex closest to origin. Updated every iteration
		var simp = [];
		var sup0 = new Point();
		var sup1 = new Point();
		for (i in 0...MAX_LOOP) {
			c0.support(-v.x, -v.y, -v.z, sup0);
			c1.support( v.x,  v.y,  v.z, sup1);

			var p = sup0.sub(sup1);

			var vLenSq = v.lengthSq();
			var pDotV = p.dot(v);
			if (!precise && pDotV > 0) {
				// Fast, but imprecise no-collision condition
				return new ColRes(false, p);
			}
			if (vLenSq-pDotV < REL*vLenSq) {
				// More precise no-collision condition
				return new ColRes(false, p);
			}

			simp.push(p);
			// Refine the simplex
			var distRes = dist(simp);
			v = distRes.point();
			simp = distRes.simp;
			if (simp.length == 4) {
				// Origin is contained, therefore contact
				break;
			}
			var maxSimpLnSq = 0.0;
			for (sp in simp) {
				maxSimpLnSq = Math.max(maxSimpLnSq, sp.lengthSq());
			}
			if (vLenSq < tol*maxSimpLnSq) {
				break;
			}
		}
		// Collision, take the closest point on the simplex as the penetration vector
		var minSimpLen = Math.POSITIVE_INFINITY;
		var minSimp = null;
		for (sp in simp) {
			var simpLen = sp.lengthSq();
			if (simpLen < minSimpLen) {
				minSimpLen = simpLen;
				minSimp = sp;
			}
		}
		return new ColRes(true, minSimp);
	}

	// Sign comparison that intentionally fails for 0 and NaN
	static inline function compSigns(v0:Float, v1:Float) {
		return ((v0>0 && v1>0) || (v0<0 && v1<0));
	}

	static function dist(simp:Array<Point>): DistRes {
		switch(simp.length) {
			case 4: return dist3D(simp);
			case 3: return dist2D(simp);
			case 2: return dist1D(simp);
			case 1: return new DistRes(simp, [1]);
			default: throw "bad simplex";
		}
	}


	// Equivalent to S3D in the paper
	static function dist3D( simp: Array<Point>): DistRes {
		Debug.assert(simp.length == 4);
		var p0 = simp[0];
		var p1 = simp[1];
		var p2 = simp[2];
		var p3 = simp[3];

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
				case 0: [p1, p2, p3];
				case 1: [p0, p2, p3];
				case 2: [p0, p1, p3];
				case 3: [p0, p1, p2];
				default: throw "Impossible";
			}
			var subRet = dist2D(subSimp);
			var d = subRet.point().lengthSq();
			if (d < bestDist) {
				bestDist = d;
				bestRet = i;
				subRets[i] = subRet;
			}
		}
		return subRets[bestRet];
	}

	// Equivalent to S2D in the paper
	static function dist2D( simp: Array<Point>): DistRes {
		Debug.assert(simp.length == 3);
		var p0 = simp[0];
		var p1 = simp[1];
		var p2 = simp[2];
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
				case 0: [p1, p2];
				case 1: [p0, p2];
				case 2: [p0, p1];
				default: throw "Impossible";
			}
			var subRet = dist1D(subSimp);
			var d = subRet.point().lengthSq();
			if (d < bestDist) {
				bestDist = d;
				bestRet = i;
				subRets[i] = subRet;
			}
		}
		return subRets[bestRet];
	}

	// Equivalent to S1D in the paper
	static function dist1D( simp: Array<Point>): DistRes {
		Debug.assert(simp.length == 2);
		var p0 = simp[0];
		var p1 = simp[1];
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
			var p = (p0.lengthSq() <= p1.lengthSq()) ? p0:p1;
			return new DistRes([p], [1]);
		}
	}
}
