package htst;

import h3d.MatrixTools;
import h3d.Vector;
import h3d.Matrix;
import h3d.TRSTrans;
import h3d.Quat;
import h3d.col.Point;
import h3d.col.HullBuilder;
import h3d.col.ConvexHull;
import h3d.phys.HullPhysics;
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

	function testHullBodyProps() {

		var cubeHull = ConvexHull.makeCubeHull();
		var cubeProps = HullPhysics.calcProperties(cubeHull, 1.0);

		Assert.floatEquals(8.0, cubeProps.mass);
		Check.point(0,0,0, cubeProps.com);

		// Check MoI to analytical solution
		var cubeMoI = 8*(4+4)/12;
		Assert.floatEquals(cubeMoI,cubeProps.moi._11);
		Assert.floatEquals(cubeMoI,cubeProps.moi._22);
		Assert.floatEquals(cubeMoI,cubeProps.moi._33);
		Assert.floatEquals(cubeMoI,cubeProps.principalMOI.x);
		Assert.floatEquals(cubeMoI,cubeProps.principalMOI.y);
		Assert.floatEquals(cubeMoI,cubeProps.principalMOI.z);

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

		Assert.floatEquals(12*(4+9)/12,offsetProps.moi._11);
		Assert.floatEquals(12*(1+9)/12,offsetProps.moi._22);
		Assert.floatEquals(12*(1+4)/12,offsetProps.moi._33);

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

	// Return an offset rectangular prism rotated around X by 60 degrees
	function makeRotatedRect() {
		var rectPts =
		[for (i in 0...8) new Point(
			(i&1 != 0) ? 0.0 : 1.0,
			(i&2 != 0) ? 0.0 : 2.0,
			(i&4 != 0) ? 0.0 : 3.0)
		];
		var rotX60 = new Quat();
		rotX60.initRotateAxis(1,0,0, Math.PI/3.0);
		var rotXMat = rotX60.toMatrix();

		var rotPts = [];
		for (p in rectPts) {
			var v = new Vector(p.x, p.y, p.z);
			v.transform(rotXMat);
			rotPts.push(v.toPoint());
		}
		// rotPts is now an offset rectangular prism, rotated by 60 degrees
		return HullBuilder.buildHull(rotPts);

	}

	function testShapeToBodyTrans() {
		// Test the system that transforms from provided shape space
		// into "body" space (aka: centered at CoM and aligned with the principal axis)
		var rotRect = makeRotatedRect();
		var props = HullPhysics.calcProperties(rotRect, 1.0);
		var bodyToShape = new TRSTrans(props.com.toVector(), props.principalRot, 1.0);
		var shapeToBody = bodyToShape.inverse();

		var stbMat = shapeToBody.toMatrix();

		var rotX60 = new Quat();
		rotX60.initRotateAxis(1,0,0, Math.PI/3.0);

		var shapeCoM = new Vector(0.5, 1, 1.5);
		shapeCoM.transform(rotX60.toMatrix());
		Check.vec3v(props.com, shapeCoM);

		var comTest = shapeCoM.clone();
		comTest.transform(stbMat);
		Check.vec3(0,0,0, comTest);

		var princAxes = MatrixTools.getColumns(props.principalRot.toMatrix());

		var pxTest = shapeCoM.clone();
		pxTest.incr(princAxes[0]);
		pxTest.transform(stbMat);
		Check.vec3(1,0,0, pxTest);

		var pyTest = shapeCoM.clone();
		pyTest.incr(princAxes[1]);
		pyTest.transform(stbMat);
		Check.vec3(0,1,0, pyTest);

		var pzTest = shapeCoM.clone();
		pzTest.incr(princAxes[2]);
		pzTest.transform(stbMat);
		Check.vec3(0,0,1, pzTest);

	}

	function testPrincipalAxes() {
		// Test that the principal axes are in fact principal for the MoI
		var rotRect = makeRotatedRect();
		var props = HullPhysics.calcProperties(rotRect, 1.0);

		var princAxes = MatrixTools.getColumns(props.principalRot.toMatrix());

		// Check that the principal axes are eigen vectors of the MoI
		var pMOI = props.principalMOI.toArray();
		for (i in 0...3) {
			var testV = princAxes[i].clone();
			Assert.floatEquals(1.0, testV.length());
			testV.transform(props.moi);
			var testVLen = testV.length();
			Assert.floatEquals(Math.abs(pMOI[i]), testVLen);
			Assert.floatEquals(pMOI[i], testV.dot3(princAxes[i]));
		}
	}

	function testMergeBody() {
		// Testing merging two rigid bodies into a single one

		var rot1 = new Quat();
		rot1.initRotateAxis(0.0, 1.0, 0.0, -Math.PI/4.0);
		var rot1Mat = rot1.toMatrix();

		var rectPts0 =
		[for (i in 0...8) new Point(
			(i&1 != 0) ? -1.0 : 1.0,
			(i&2 != 0) ? -3.0 : 3.0,
			(i&4 != 0) ? -2.0 : 2.0)
		];

		var rectPts1 =
		[for (i in 0...8) new Point(
			(i&1 != 0) ? -2.0 : 2.0,
			(i&2 != 0) ? -3.0 : 3.0,
			(i&4 != 0) ?  0.0 : 2.0)
		];
		for ( p in rectPts1) {
			p.transform(rot1Mat);
		}
		var hull0 = HullBuilder.buildHull(rectPts0);
		var hull1 = HullBuilder.buildHull(rectPts1);
		var props0 = HullPhysics.calcProperties(hull0, 1.0);
		var props1 = HullPhysics.calcProperties(hull1, 1.0);

		var trans0 = TRSTrans.fromTrans(new Vector(1.0, 0.0, 0.0));
		var trans1 = TRSTrans.fromRot(rot1);

		var mergedProps = HullPhysics.mergeBodies(props0, trans0, props1, trans1);

		// Merged props should have the properties of a 4x6x4 rectangular prism at the origin
		Assert.floatEquals(96, mergedProps.mass);
		Check.point(0,0,0, mergedProps.com);

		var mergedMoIxz = 96*(16+36)/12;
		var mergedMoIy = 96*(16+16)/12;
		Assert.floatEquals(mergedMoIxz, mergedProps.moi._11);
		Assert.floatEquals(mergedMoIy, mergedProps.moi._22);
		Assert.floatEquals(mergedMoIxz, mergedProps.moi._33);
	}
}
