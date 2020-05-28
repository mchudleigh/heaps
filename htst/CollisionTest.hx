package htst;

import h3d.col.Point;
import utest.Assert;
import h3d.col.HullBuilder;
import h3d.col.ConvexHull;
import h3d.col.HullCollision;

class CollisionTest extends utest.Test {

	static function checkPoint(x, y, z, p, ?pos:haxe.PosInfos) {
		Assert.floatEquals(x, p.x, 'X component wrong. Expected: $x Got: ${p.x}', pos);
		Assert.floatEquals(y, p.y, 'Y component wrong. Expected: $y Got: ${p.x}', pos);
		Assert.floatEquals(z, p.z, 'Z component wrong. Expected: $z Got: ${p.z}', pos);
	}
	static function checkFloatArray(exp:Array<Float>, val:Array<Float>, ?pos:haxe.PosInfos) {
		Assert.equals(exp.length, val.length,
			 'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			Assert.floatEquals(exp[i], val[i],
				'Float array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
		}
	}
	static function checkArray(exp:Array<Dynamic>, val:Array<Dynamic>, ?pos:haxe.PosInfos) {
		Assert.equals(exp.length, val.length,
			'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			Assert.equals(exp[i], val[i],
				'Array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
		}
	}

	static function checkArrayOptions(exp:Array<Dynamic>, val:Array<Dynamic>, ?pos:haxe.PosInfos) {
		// Scratch
		var arrayClass = Type.resolveClass("Array");

		Assert.equals(exp.length, val.length,
			'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			var expType = Type.getClass(exp[i]);
			if (expType == arrayClass) {
				// This is a list of possible options. Check that one matches
				var optionList = cast (exp[i], Array<Dynamic>);
				var found = false;
				for (o in optionList) {
					if (val[i] == o) found = true;
				}
				Assert.isTrue(found,
					'Option failure in array at element $i', pos);
			} else {
			Assert.equals(exp[i], val[i],
				'Array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
			}
		}
	}

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
		checkArray([tx0], ret.simp);
		checkFloatArray([1], ret.barCoords);
		checkPoint(1,1,1, ret.point());

		// Check inside the simplex
		tx0 = new Point(1,1,1);
		tx1 = new Point(-3,1,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		checkArray([tx0, tx1], ret.simp);
		checkFloatArray([0.75, 0.25], ret.barCoords);
		checkPoint(0,1,1, ret.point());

		// Check degenerate
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,1,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		checkArray([tx0], ret.simp);
		checkFloatArray([1], ret.barCoords);
		checkPoint(1,1,1, ret.point());

		// Check inside the simplex (y axis)
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,-3,1);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		checkArray([tx0, tx1], ret.simp);
		checkFloatArray([0.75, 0.25], ret.barCoords);
		checkPoint(1,0,1, ret.point());

		// Check inside the simplex (z axis)
		tx0 = new Point(1,1,1);
		tx1 = new Point(1,1,-3);
		ret =  @:privateAccess HullCollision.dist1D([tx0, tx1]);
		checkArray([tx0, tx1], ret.simp);
		checkFloatArray([0.75, 0.25], ret.barCoords);
		checkPoint(1,1,0, ret.point());
	}

	function testHullCollDist2D() {
		var p0, p1, p2, ret;

		// Test in simplex (X projection)
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArray([p0, p1, p2], ret.simp);
		checkFloatArray([1/3, 1/3, 1/3], ret.barCoords);
		checkPoint(1,0,0, ret.point());

		// Test in simplex (Y projection)
		p0 = new Point(-1, 1, -1);
		p1 = new Point(-1, 1,  2);
		p2 = new Point( 2, 1, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArray([p0, p1, p2], ret.simp);
		checkFloatArray([1/3, 1/3, 1/3], ret.barCoords);
		checkPoint(0,1,0, ret.point());

		// Test in simplex (Z projection)
		p0 = new Point(-1, -1, 1);
		p1 = new Point(-1,  2, 1);
		p2 = new Point( 2, -1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArray([p0, p1, p2], ret.simp);
		checkFloatArray([1/3, 1/3, 1/3], ret.barCoords);
		checkPoint(0,0,1, ret.point());

		// Test on edge
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 0);
		p2 = new Point(1, 0, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArray([p1, p2], ret.simp);
		checkFloatArray([1/2, 1/2], ret.barCoords);
		checkPoint(1,0.5,0.5, ret.point());

		// Test on point
		p0 = new Point(1, 2, 1);
		p1 = new Point(1, 2, 2);
		p2 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArray([p2], ret.simp);
		checkFloatArray([1], ret.barCoords);
		checkPoint(1,1,1, ret.point());

		// Test degenerate as line
		p0 = new Point(1, 0,  1);
		p1 = new Point(1, 0,  1);
		p2 = new Point(1, 2, -1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArrayOptions([[p0, p1], p2], ret.simp);
		checkFloatArray([3/4, 1/4], ret.barCoords);
		checkPoint(1,0.5,0.5, ret.point());

		// Test degenerate as point
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 1);
		p2 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist2D([p0, p1, p2]);
		checkArrayOptions([[p0,p1,p2]], ret.simp);
		checkFloatArray([1], ret.barCoords);
		checkPoint(1,1,1, ret.point());

	}

	function testHullCollDist3D() {
		var p0, p1, p2, p3, ret;

		// Test in simplex
		p0 = new Point(-1, -1, -1);
		p1 = new Point( 3, -1, -1);
		p2 = new Point(-1,  3, -1);
		p3 = new Point(-1, -1,  3);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		checkArray([p0, p1, p2, p3], ret.simp);
		checkFloatArray([1/4, 1/4, 1/4, 1/4], ret.barCoords);
		checkPoint(0,0,0, ret.point());

		// Test against face
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		p3 = new Point(2,  3,  4);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		checkArray([p0, p1, p2], ret.simp);
		checkFloatArray([1/3, 1/3, 1/3], ret.barCoords);
		checkPoint(1,0,0, ret.point());

		// Test against face (degenerate)
		p0 = new Point(1, -1, -1);
		p1 = new Point(1, -1,  2);
		p2 = new Point(1,  2, -1);
		p3 = new Point(1,  2, -1);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		checkArrayOptions([p0,p1,[p2,p3]], ret.simp);
		checkFloatArray([1/3, 1/3, 1/3], ret.barCoords);
		checkPoint(1,0,0, ret.point());

		// Test against line (degenerate)
		p0 = new Point(1, 0, 1);
		p1 = new Point(1, 0, 1);
		p2 = new Point(1, 1, 0);
		p3 = new Point(1, 1, 0);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		checkArrayOptions([[p0,p1],[p2,p3]], ret.simp);
		checkFloatArray([0.5,0.5], ret.barCoords);
		checkPoint(1,0.5,0.5, ret.point());

		// Test against point (degenerate)
		p0 = new Point(1, 1, 1);
		p1 = new Point(1, 1, 1);
		p2 = new Point(1, 1, 1);
		p3 = new Point(1, 1, 1);
		ret =  @:privateAccess HullCollision.dist3D([p0, p1, p2, p3]);
		checkArrayOptions([[p0,p1,p2,p3]], ret.simp);
		checkFloatArray([1], ret.barCoords);
		checkPoint(1,1,1, ret.point());

	}
}
