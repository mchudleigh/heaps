package h3d.col;



// A simple data container representing a point on a
// Minkowski difference of two convex colliders (see the GJK algo
// if that doesn't make sense)
class HullColPoint {

	// point = srcA - srcB
	public var point: Point;
	public var srcA: Point;
	public var srcB: Point;

	public function new(a:Point, b:Point) {
		srcA = a.clone();
		srcB = b.clone();
		point = a.sub(b);
	}
}
