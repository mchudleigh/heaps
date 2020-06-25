package h3d.col;

import h3d.Quat;

// Utilities to calculate the physical properties of
// convex hulls (specifically mass, center of mass and
// moment of inertia)

// The physical proerties of a rigid body (excluding collision)
class PhysProps {

	public var mass: Float;

	// Center of Mass
	public var com: Point;
	public var moi: Matrix;

	// The moment of inertia about the CoM on the principal axis
	// public var principalMOI: Point;
	// The rotation for local coords to principal axis
	// public var principalRot: Quat;

	public function new() {}
}

class HullPhysics {

	// Return the area of triangle formed by 3 points
	static function triangleArea(p0:Point, p1:Point, p2:Point): Float {
		var d0 = p1.sub(p0);
		var d1 = p2.sub(p0);
		var c = d0.cross(d1);
		return c.length()*0.5;
	}

	// Get a point inside the volume
	static function innerPoint(hull: ConvexHull):Point {
		var accum = new Point();
		for (i in hull.faces) {
			var p = hull.points[i];
			accum.inc(p.toPoint());
		}
		accum.scale(1.0/hull.faces.length);
		return accum;
	}

	static function calcMoI(hull:ConvexHull, com:Point, faceVols:Array<Float>):Matrix {
		// Build up the moment of inertia around the Center of Mass
		// by adding up tetrahedra formed from each face to the CoM
		// This is derived from (see arbitrary tetrahedron at the bottom):
		// https://en.wikipedia.org/wiki/List_of_moments_of_inertia
		function f(a:Array<Float>,b:Array<Float>):Float {
			var ret = a[0]*b[0]+a[1]*b[1]+a[2]*b[2];
			for (i in 0...3)
				for (j in 0...3)
					ret+=a[i]*b[j];

			return ret;
		}

		var moiAccum = new Matrix();
		moiAccum.zero(); moiAccum._44 = 1.0;

		for (fInd in 0...Std.int(hull.faces.length/3)) {
			var op0 = hull.points[hull.faces[fInd*3 + 0]].toPoint();
			var op1 = hull.points[hull.faces[fInd*3 + 1]].toPoint();
			var op2 = hull.points[hull.faces[fInd*3 + 2]].toPoint();
			var vol = faceVols[fInd];

			// Recenter at CoM
			var p0 = op0.sub(com);
			var p1 = op1.sub(com);
			var p2 = op2.sub(com);

			var xs = [p0.x, p1.x, p2.x];
			var ys = [p0.y, p1.y, p2.y];
			var zs = [p0.z, p1.z, p2.z];

			var scale = vol/20.0;
			moiAccum._11 += scale*(f(ys,ys) + f(zs, zs));
			moiAccum._22 += scale*(f(zs,zs) + f(xs, xs));
			moiAccum._33 += scale*(f(xs,xs) + f(ys, ys));

			var xyTerm = -1.0*scale*f(xs, ys);
			moiAccum._12 += xyTerm;
			moiAccum._21 += xyTerm;

			var xzTerm = -1.0*scale*f(xs, zs);
			moiAccum._13 += xzTerm;
			moiAccum._31 += xzTerm;

			var yzTerm = -1.0*scale*f(ys, zs);
			moiAccum._23 += yzTerm;
			moiAccum._32 += yzTerm;
		}
		return moiAccum;
	}

	static function calcCoM(hull: ConvexHull): { com: Point, vol:Float, faceVols: Array<Float> } {
		var ip = innerPoint(hull);
		// Make a series of tetrahedra from the mean point to all the faces
		// and average their weighted CoMs

		var volAccum = 0.0;
		var comAccum = new Point();
		var faceVols = [];

		for (fInd in 0...Std.int(hull.faces.length/3)) {
			var p0 = hull.points[hull.faces[fInd*3 + 0]].toPoint();
			var p1 = hull.points[hull.faces[fInd*3 + 1]].toPoint();
			var p2 = hull.points[hull.faces[fInd*3 + 2]].toPoint();
			var area = triangleArea(p0, p1, p2);
			var h = -1.0*hull.facePlanes[fInd].distance(ip);
			var volume = h*area/3.0;
			volAccum += volume;
			faceVols.push(volume);

			// Add the tetrahedron's barycenter weighted by volume to the
			// CoM accumulator
			var scale = volume*0.25;
			comAccum.x += scale*(p0.x + p1.x + p2.x + ip.x);
			comAccum.y += scale*(p0.y + p1.y + p2.y + ip.y);
			comAccum.z += scale*(p0.z + p1.z + p2.z + ip.z);
		}
		// Divide CoM by total volume
		comAccum.scale(1.0/volAccum);

		return { com: comAccum, vol: volAccum, faceVols: faceVols };
	}

	public static function calcProperties(hull: ConvexHull, density: Float): PhysProps {

		var ret = new PhysProps();
		var com = calcCoM(hull);

		var moi = calcMoI(hull, com.com, com.faceVols);
		moi.scale(density, density, density);

		ret.mass = com.vol*density;
		ret.com = com.com.clone();
		ret.moi = moi;

		return ret;
	}

}
