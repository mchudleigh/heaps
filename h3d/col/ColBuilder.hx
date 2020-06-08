package h3d.col;

import h3d.col.ConvexCollider.PointCol;
import h3d.col.ConvexCollider.SphereCol;
import h3d.col.ConvexCollider.CircleCol;
import h3d.col.ConvexCollider.LineCol;
import h3d.col.ConvexCollider.CompoundCol;
import h3d.col.ConvexCollider.TransformCol;

// Convenience class to generate common collision shapes
class ColBuilder {
	public static function point(p, id): ConvexCollider {
		return new PointCol(p,id);
	}
	public static function sphere(center, radius, id): ConvexCollider {
		return new SphereCol(center, radius, id);
	}
	public static function circle(center, normal, radius, id): ConvexCollider {
		return new CircleCol(center, normal, radius, id);
	}
	public static function line(p0, p1, id): ConvexCollider {
		return new LineCol(p0, p1, id);
	}
	public static function compound(subCols, id): ConvexCollider {
		return new CompoundCol(subCols, id);
	}
	public static function transform(col, mat, id): ConvexCollider {
		return new TransformCol(col, mat, id);
	}


	// An origin centered cube of given dimensions
	public static function cube(xDim, yDim, zDim, id): ConvexCollider {
		var xCol = new LineCol(new Point(xDim/2,0,0), new Point(-xDim/2,0,0), -id);
		var yCol = new LineCol(new Point(0,yDim/2,0), new Point(0,-yDim/2,0), -id);
		var zCol = new LineCol(new Point(0,0,zDim/2), new Point(0,0,-zDim/2), -id);
		return new CompoundCol([xCol,yCol,zCol],id);
	}
	// A Z aligned capsule (length is center to center, not tip to tip)
	public static function capsule(radius, len, id) {
		var spCol = new SphereCol(new Point(0,0,0), radius, -id);
		var lnCol = new LineCol(new Point(0,0,len/2), new Point(0,0,-len/2), -id);
		return new CompoundCol([spCol, lnCol], id);
	}

	// A Z aligned cylinder
	public static function cylinder(radius, len, id) {
		var spCol = new CircleCol(new Point(0,0,0), new Point(0,0,1), radius, -id);
		var lnCol = new LineCol(new Point(0,0,len/2), new Point(0,0,-len/2), -id);
		return new CompoundCol([spCol, lnCol], id);
	}

	// Round the edges of an existing collider (will increase extents by radius)
	public static function round(col, radius, id) {
		var spCol = new SphereCol(new h3d.col.Point(0,0,0), radius, -id);
		return new CompoundCol([col, spCol], id);
	}
	// Sweep an existing collider from startP to endP
	public static function sweep(col, startP, endP, id) {
		var lnCol = new LineCol(startP, endP, -id);
		return new CompoundCol([col, lnCol], id);
	}
}
