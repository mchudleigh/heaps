package htst;

import h3d.col.Point;
import utest.Assert;
import h3d.col.HullBuilder;
import h3d.col.ConvexHull;
import h3d.col.HullCollision;

class CollisionTest extends utest.Test {

	function testCubeHull() {

		var cube = ConvexHull.makeCubeHull();
		Assert.notNull(cube);
		var builtCube = HullBuilder.makeTestCube();
		Assert.notNull(builtCube);

		var origPoint = new h3d.col.Point(0,0,0);
		Assert.isTrue(cube.containsPoint(origPoint));
		Assert.isTrue(builtCube.containsPoint(origPoint));

		var farPoint = new h3d.col.Point(2,3,42);
		Assert.isFalse(cube.containsPoint(farPoint));
		Assert.isFalse(builtCube.containsPoint(farPoint));
	}

	// Test the dist1D function of HullCollision
	function testHullCollDist1D() {
		// Check past the simplex
		var tx0 = new Point(1,1,1);
		var tx1 = new Point(3,1,1);
		var ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		Check.array([tx0], ret.simp);
		Check.floatArray([1], ret.barCoords);
		Check.point(1,1,1, ret.point());

		// Check inside the simplex
		tx0 = new Point(1,1,1);
		tx1 = new Point(-3,1,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		Check.array([tx0, tx1], ret.simp);
		Check.floatArray([0.75, 0.25], ret.barCoords);
		Check.point(0,1,1, ret.point());

		// Check degenerate
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,1,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		Check.array([tx0], ret.simp);
		Check.floatArray([1], ret.barCoords);
		Check.point(1,1,1, ret.point());

		// Check inside the simplex (y axis)
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,-3,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		Check.array([tx0, tx1], ret.simp);
		Check.floatArray([0.75, 0.25], ret.barCoords);
		Check.point(1,0,1, ret.point());

		// Check inside the simplex (z axis)
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,1,-3);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		Check.array([tx0, tx1], ret.simp);
		Check.floatArray([0.75, 0.25], ret.barCoords);
		Check.point(1,1,0, ret.point());
	}

	function testHullCollDist2D() {
		var p0, p1, p2, ret;

		// Test in simplex (X projection)
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.array([p0, p1, p2], ret.simp);
		Check.floatArray([1/3, 1/3, 1/3], ret.barCoords);
		Check.point(1,0,0, ret.point());

		// Test in simplex (Y projection)
		p0 = new Point(-1, 1, -1);
		p1 = new Point(-1, 1,  2);
		p2 = new Point( 2, 1, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.array([p0, p1, p2], ret.simp);
		Check.floatArray([1/3, 1/3, 1/3], ret.barCoords);
		Check.point(0,1,0, ret.point());

		// Test in simplex (Z projection)
		p0 = new Point(-1, -1, 1);
		p1 = new Point(-1,  2, 1);
		p2 = new Point( 2, -1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.array([p0, p1, p2], ret.simp);
		Check.floatArray([1/3, 1/3, 1/3], ret.barCoords);
		Check.point(0,0,1, ret.point());

		// Test on edge
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 0);
		p2 = new Point(1, 0, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.array([p1, p2], ret.simp);
		Check.floatArray([1/2, 1/2], ret.barCoords);
		Check.point(1,0.5,0.5, ret.point());

		// Test on point
		p0 = new Point(1, 2, 1);
		p1 = new Point(1, 2, 2);
		p2 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.array([p2], ret.simp);
		Check.floatArray([1], ret.barCoords);
		Check.point(1,1,1, ret.point());

		// Test degenerate as line
		p0 = new Point(1, 0,  1);
		p1 = new Point(1, 0,  1);
		p2 = new Point(1, 2, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.arrayOptions([[p0, p1], p2], ret.simp);
		Check.floatArray([3/4, 1/4], ret.barCoords);
		Check.point(1,0.5,0.5, ret.point());

		// Test degenerate as point
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 1);
		p2 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		Check.arrayOptions([[p0,p1,p2]], ret.simp);
		Check.floatArray([1], ret.barCoords);
		Check.point(1,1,1, ret.point());

	}

	function testHullCollDist3D() {
		var p0, p1, p2, p3, ret;

		// Test in simplex
		p0 = new Point(-1, -1, -1);
		p1 = new Point( 3, -1, -1);
		p2 = new Point(-1,  3, -1);
		p3 = new Point(-1, -1,  3);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		Check.array([p0, p1, p2, p3], ret.simp);
		Check.floatArray([1/4, 1/4, 1/4, 1/4], ret.barCoords);
		Check.point(0,0,0, ret.point());

		// Test against face
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		p3 = new Point(2,  3,  4);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		Check.array([p0, p1, p2], ret.simp);
		Check.floatArray([1/3, 1/3, 1/3], ret.barCoords);
		Check.point(1,0,0, ret.point());

		// Test against face (degenerate)
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		p3 = new Point(1,  2, -1);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		Check.arrayOptions([p0,p1,[p2,p3]], ret.simp);
		Check.floatArray([1/3, 1/3, 1/3], ret.barCoords);
		Check.point(1,0,0, ret.point());

		// Test against line (degenerate)
		p0 = new Point(1, 0, 1);
		p1 = new Point(1, 0, 1);
		p2 = new Point(1, 1, 0);
		p3 = new Point(1, 1, 0);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		Check.arrayOptions([[p0,p1],[p2,p3]], ret.simp);
		Check.floatArray([0.5,0.5], ret.barCoords);
		Check.point(1,0.5,0.5, ret.point());

		// Test against point (degenerate)
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 1);
		p2 = new Point(1, 1, 1);
		p3 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		Check.arrayOptions([[p0,p1,p2,p3]], ret.simp);
		Check.floatArray([1], ret.barCoords);
		Check.point(1,1,1, ret.point());

	}

	function testSphereGJK() {
		// Test collision based on some simple sphere geometry
		var sph0 = new SphereCollider(new Point(1,0,0), 1.0, 0);
		var sph1 = new SphereCollider(new Point(5,0,0), 2.0, 1);

		var coll = new HullCollision();
		var res;
		res = coll.testCollision(sph0, sph1, true);
		Assert.isFalse(res.collides);
		Assert.floatEquals(1, res.vec.length());

		sph1.center = new Point(5,3,0); // Make a 3,4,5 triangle
		res = coll.testCollision(sph0, sph1, true);
		Assert.isFalse(res.collides);
		Assert.floatEquals(2, res.vec.length());
	}
}
