package h3d.col;

import hxd.Debug;

interface ConvexCollider {
	public function getID():Int;
	public function support(x:Float,y:Float,z:Float, out:Point):Void;
	public function startPoint(): Point;
}

class PointCol implements ConvexCollider {
	final point: Point;
	final id: Int;
	public function new(p,i) {
		this.point = p;
		this.id = i;
	}
	public function getID():Int { return id; }

	public function support(x:Float,y:Float,z:Float, out:Point) {
		out.x = point.x; out.y = point.y; out.z = point.z;
	}
	public function startPoint(): Point {
		return point;
	}
}

class SphereCol implements ConvexCollider {
	final center: Point;
	final radius: Float;
	final id: Int;
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
		var ret = center.clone();
		ret.x+=radius;
		return ret;
	}
}

class CircleCol implements ConvexCollider {
	final center: Point;
	final normal: Point;
	final radius: Float;
	final id: Int;
	public function new(c, n, r, i) {
		center = c;
		normal = n;
		normal.normalize();
		radius = r;
		id = i;
	}
	public function getID() { return id;}

	public function support(x:Float, y:Float, z:Float, out:Point) {
		out.x = x; out.y = y; out.z = z;
		// Subtract the normal part from the direction
		var dot = out.dot(normal);
		out.x -= dot*normal.x;
		out.y -= dot*normal.y;
		out.z -= dot*normal.z;

		var testDot = out.x*normal.x + out.y*normal.y + out.z*normal.z;
		Debug.assert(Math.abs(testDot) < 0.0001);

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

class LineCol implements ConvexCollider {

	final p0: Point;
	final p1: Point;
	final dir: Point;
	final id: Int;

	public function new(p0, p1, id) {
		this.p0 = p0;
		this.p1 = p1;
		this.id = id;
		dir = p1.sub(p0);
	}

	public function getID():Int {
		return id;
	}

	public function support(x:Float,y:Float,z:Float, out:Point):Void {
		var dot = x*dir.x + y*dir.y + z*dir.z;
		if (dot > 0) {
			out.x = p1.x;
			out.y = p1.y;
			out.z = p1.z;
		} else {
			out.x = p0.x;
			out.y = p0.y;
			out.z = p0.z;
		}
	}
	public function startPoint(): Point {
		return p0;
	}

}
class HullCol implements ConvexCollider {
	final hull: ConvexHull;
	final id:Int;
	final temp: Vector;
	public function new(hull, id) {
		this.hull = hull;
		this.id = id;
		temp = new Vector();
	}
	public function getID():Int {
		return id;
	}

	public function support(x:Float,y:Float,z:Float, out:Point) {
		temp.x = x; temp.y = y; temp.z = z;
		var p = hull.support(temp);
		out.x = p.x; out.y = p.y; out.z = p.z;
	}

	public function startPoint(): Point {
		temp.x = 1; temp.y = 0; temp.z = 0;
		return hull.support(temp).toPoint();
	}

}


class CompoundCol implements ConvexCollider {
	final subCols:Array<ConvexCollider>;
	final id:Int;
	public function new(subCols, id) {
		this.subCols = subCols;
		this.id = id;
	}

	public function getID():Int {
		return id;
	}
	public function support(x:Float,y:Float,z:Float, out:Point) {
		var temp = new Point();
		out.x = 0; out.y = 0; out.z = 0;
		for (c in subCols) {
			c.support(x,y,z,temp);
			out.x += temp.x; out.y += temp.y; out.z += temp.z;
		}
	}

	public function startPoint(): Point {
		var ret = new Point();
		for (c in subCols) {
			var sp = c.startPoint();
			ret.x += sp.x; ret.y += sp.y; ret.z += sp.z;
		}
		return ret;
	}

}

class TransformCol implements ConvexCollider {
	final subCol: ConvexCollider;
	final id: Int;
	var mat: h3d.Matrix;
	var invMat: h3d.Matrix;
	var temp: h3d.Vector;

	public function new(col, mat, id) {
		this.subCol = col;
		this.id = id;
		this.mat = mat;
		invMat = new h3d.Matrix();
		invMat.initInverse(mat);
		temp = new h3d.Vector();
	}
	public function setMatrix(mat) {
		this.mat = mat;
		invMat.initInverse(mat);
	}
	public function getID():Int {
		return id;
	}

	public function support(x:Float,y:Float,z:Float, out:Point) {
		// Transform vector into sub-collider space
		temp.x = x; temp.y = y; temp.z = z; temp.w = 0;
		temp.transform3x3(invMat);
		subCol.support(temp.x, temp.y, temp.z,out);

		// Transform the point back to external space
		temp.x = out.x; temp.y = out.y; temp.z = out.z; temp.w =1;
		temp.transform(mat);
		out.x = temp.x; out.y = temp.y; out.z = temp.z;
	}

	public function startPoint(): Point {
		var sp = subCol.startPoint();
		temp.x = sp.x; temp.y = sp.y; temp.z = sp.z; temp.w =1;
		temp.transform(mat);
		return temp.toPoint();
	}

}

