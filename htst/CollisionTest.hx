package htst;

import h3d.col.Point;
import utest.Assert;
import h3d.col.HullBuilder;
import h3d.col.ConvexHull;
import h3d.col.HullCollision;
import h3d.col.ColBuilder;

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
		var sph0 = ColBuilder.sphere(new Point(1,0,0), 1.0, 0);
		var sph1 = ColBuilder.sphere(new Point(5,0,0), 2.0, 1);

		var coll = new HullCollision();
		var res;
		res = coll.testCollision(sph0, sph1, true);
		Assert.isFalse(res.collides);
		Assert.floatEquals(1, res.vec.length());

		sph1 = ColBuilder.sphere(new Point(5,3,0), 2.0, 1); // Make a 3,4,5 triangle
		res = coll.testCollision(sph0, sph1, true);
		Assert.isFalse(res.collides);
		Assert.floatEquals(2, 0.0001, res.vec.length());

	}
	function testCubeGJK() {

		var cube, pt;
		var coll = new HullCollision();
		var res;

		cube = ColBuilder.cube(2,3,5, 1);

		pt = ColBuilder.point(new Point(0.05,0,2.49), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0.01, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		pt = ColBuilder.point(new Point(0.0,0,2.49), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0.01, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		pt = ColBuilder.point(new Point(0.0,0,2.5), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		pt = ColBuilder.point(new Point(0.05,0,2.50), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		pt = ColBuilder.point(new Point(0,1,2.55), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isFalse(res.collides);
		Check.point(0,0,-0.05, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		// Corner collision
		pt = ColBuilder.point(new Point(0.99,1.45,2.45), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isTrue(res.collides);
		Check.point(0.01,0,0, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		// Corner miss
		pt = ColBuilder.point(new Point(0.99,1.5,2.51), 2);
		res = coll.testCollision(cube, pt, true);
		Assert.isFalse(res.collides);
		Check.point(0.0,0,-0.01, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		// A 1,1,1 cube on the z axis
		var cube2 = ColBuilder.compound([
			ColBuilder.cube(1,1,1, 42),
			ColBuilder.point(new Point(0,0,2.5), 43)
		], 44);
		res = coll.testCollision(cube, cube2, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0.5, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

		var sphere = ColBuilder.sphere(new Point(0,0,2.5),0.5, 42);
		res = coll.testCollision(cube, sphere, true);
		Assert.isTrue(res.collides);
		Check.point(0,0,0.5, res.vec);
		Assert.isTrue(coll.getLastLoopCount() < 20);

	}
	function testRandomSphereCol() {
		var coll = new HullCollision();
		var res;

		function getRandPt(min,max): Point {
			var x = (max-min)*Math.random() + min;
			var y = (max-min)*Math.random() + min;
			var z = (max-min)*Math.random() + min;
			return new Point(x,y,z);
		}

		var numTests = 0;
		while (numTests < 50) {
			// Generate random spheres and make sure they do not collide
			// Random vals on [-5,5]
			var p0 = getRandPt(-5,5);
			var p1 = getRandPt(-5,5);

			// Radius up to 3
			var rad0 = 3*Math.random();
			var rad1 = 3*Math.random();
			var radSum = rad0 + rad1;
			var diff = p0.sub(p1);
			var dist = diff.length();
			if (radSum+0.01 > dist) {
				// collision, skip it
				continue;
			}
			diff.normalize();
			diff.scale(dist-rad0-rad1);
			var sp0 = ColBuilder.sphere(p0, rad0, 1);
			var sp1 = ColBuilder.sphere(p1, rad1, 1);
			res = coll.testCollision(sp0, sp1, true);
			Assert.isFalse(res.collides);
			// calculate expected relative distance
			var dLen = diff.length();
			var thresh = Math.max(dLen*0.011, 0.001); // Actual setting is 0.01

			// if (res.collides || Check.point(diff.x, diff.y, diff.z, res.vec, thresh)) {
			// 	var res2 = coll.testCollision(sp0, sp1, true);
			// }
			numTests++;
		}
		numTests = 0;
		//return;
		// Generate 50 collisions
		while(numTests < 50) {
			var p0 = getRandPt(-5,5);
			var p1 = getRandPt(-5,5);

			// Radius up to 3
			var rad0 = 4*Math.random();
			var rad1 = 4*Math.random();
			var diff = p0.sub(p1);
			var dist = diff.length();
			var radSum = rad0+rad1;
			if ((rad0+rad1)-0.001 < dist) {
				// no collision, skip it
				continue;
			}
			diff.normalize();
			diff.scale(dist-radSum);
			var sp0 = ColBuilder.sphere(p0, rad0, 1);
			var sp1 = ColBuilder.sphere(p1, rad1, 1);
			res = coll.testCollision(sp0, sp1, true);
			var numLoops = coll.getLastLoopCount();
			Assert.isTrue(res.collides);
			Check.point(diff.x, diff.y, diff.z, res.vec, 0.05);
			// if (!res.collides || Check.point(diff.x, diff.y, diff.z, res.vec, 0.05)) {
			// 	var res2 = coll.testCollision(sp0, sp1, true);
			// }
			numTests++;
		}
	}
}
