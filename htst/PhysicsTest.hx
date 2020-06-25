package htst;

import h3d.col.Point;
import h3d.col.HullBuilder;
import h3d.col.ConvexHull;
import h3d.col.HullPhysics;
import utest.Assert;
import htst.Check;

class PhysicsTest extends utest.Test {
	function makeCylinderHull(r:Float, h:Float) {

		var pts = [];
		var numSamples = 400;
		for (i in 0...numSamples) {
			var theta = (i/numSamples)*2*Math.PI;
			var x = r*Math.cos(theta);
			var y = r*Math.sin(theta);
			pts.push(new Point(x,y, h/2.0));
			pts.push(new Point(x,y,-h/2.0));
		}
		return HullBuilder.buildHull(pts, 1000);
	}

	function testHullPhysicalProps() {

		var cubeHull = ConvexHull.makeCubeHull();
		var cubeProps = HullPhysics.calcProperties(cubeHull, 1.0);

		Assert.floatEquals(8.0, cubeProps.mass);
		Check.point(0,0,0, cubeProps.com);

		var offSetCubePts =
			[for (i in 0...8) new Point(
				(i&1 != 0) ? 0.0 : 1.0,
				(i&2 != 0) ? 0.0 : 2.0,
				(i&4 != 0) ? 0.0 : 3.0)
			];

		var offsetCube = HullBuilder.buildHull(offSetCubePts);
		var offsetProps = HullPhysics.calcProperties(offsetCube, 2.0);
		Assert.floatEquals(12.0, offsetProps.mass);
		Check.point(0.5,1.0,1.5, offsetProps.com);

		var tetraHull = ConvexHull.makeTetraHull();
		var tetraProps = HullPhysics.calcProperties(tetraHull, 1.0);
		Assert.floatEquals(1.0, tetraProps.mass);
		var rt3 = Math.sqrt(3);
		Check.point(2.0*rt3/3.0, 0.0, rt3/4.0, tetraProps.com);

		// Make a cylinder and test properties versus analytical solution
		var cylR = 9;
		var cylH = 10;
		var cylHull = makeCylinderHull(cylR, cylH);
		var cylProps = HullPhysics.calcProperties(cylHull, 1.0);
		var cylVol = Math.PI*cylR*cylR*cylH;
		Assert.floatEquals(cylVol, cylProps.mass, cylVol*0.01);
		Check.point(0.0,0.0,0.0, cylProps.com, 0.0001);
		var zMOI = cylVol*cylR*cylR/2.0;
		var xyMOI = cylVol*(3*cylR*cylR + cylH*cylH)/12;
		Assert.floatEquals( zMOI, cylProps.moi._33,  zMOI*0.01);
		Assert.floatEquals(xyMOI, cylProps.moi._11, xyMOI*0.01);
		Assert.floatEquals(xyMOI, cylProps.moi._22, xyMOI*0.01);
	}
}
