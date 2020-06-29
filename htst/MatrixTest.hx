package htst;


import h3d.Matrix;
import h3d.MatrixTools;
import h3d.Vector;
import utest.Assert;

// This is a loose collection of particular matrix tests.
// It is not intended to be comprehensive.
class MatrixTest extends utest.Test {

	// Return a value in the range [-100,100]
	function randVal() {
		return -100 + 200*Math.random();
	}

	// Generate a random 3x3 matrix with elements
	// in the range -100-100
	// (Heaps does not have a dedicated 3x3, so it is returned
	// in the upper 3x3 of a 4x4)
	function random3x3() {
		var ret = Matrix.I();
		ret._11 = randVal();
		ret._12 = randVal();
		ret._13 = randVal();

		ret._21 = randVal();
		ret._22 = randVal();
		ret._23 = randVal();

		ret._31 = randVal();
		ret._32 = randVal();
		ret._33 = randVal();

		return ret;
	}

	function random4x4() {
		var ret = Matrix.I();
		ret._11 = randVal();
		ret._12 = randVal();
		ret._13 = randVal();
		ret._14 = randVal();

		ret._21 = randVal();
		ret._22 = randVal();
		ret._23 = randVal();
		ret._24 = randVal();

		ret._31 = randVal();
		ret._32 = randVal();
		ret._33 = randVal();
		ret._34 = randVal();

		ret._41 = randVal();
		ret._42 = randVal();
		ret._43 = randVal();
		ret._44 = randVal();

		return ret;
	}

	function randomVec3() {
		var ret = new Vector();
		ret.x = randVal();
		ret.y = randVal();
		ret.z = randVal();
		ret.w = 1.0;
		return ret;
	}

	function randomVec4() {
		var ret = new Vector();
		ret.x = randVal();
		ret.y = randVal();
		ret.z = randVal();
		ret.w = randVal();
		return ret;
	}

	function testHouseholder3() {
		var m = random3x3();
		var n = randomVec3();
		n.normalize();
		//var n = new Vector(1,0,0);
		var hh = new Matrix();

		MatrixTools.hhRef3(n, hh);
		var hhm = new Matrix();
		hhm.multCols(hh, m);

		var mCols = MatrixTools.getColumns(m);
		var hhmCols = MatrixTools.getColumns(hhm);
		for (i in 0...3) {
			// The columns should individually be reflected
			var ref = mCols[i].reflect(n);
			Check.vec3v(ref, hhmCols[i]);
		}
	}

	function testHouseholder4() {
		var m = random4x4();
		var n = randomVec4();
		n.normalize4();
		//var n = new Vector(1,0,0,0);
		var hh = new Matrix();

		MatrixTools.hhRef4(n, hh);
		var hhm = new Matrix();
		hhm.multCols(hh, m);

		var mCols = MatrixTools.getColumns(m);
		var hhmCols = MatrixTools.getColumns(hhm);
		for (i in 0...4) {
			// The columns should individually be reflected
			var ref = mCols[i].reflect4(n);
			Check.vec4v(ref, hhmCols[i]);
		}
	}

	function testDoubleCross() {
		var v = randomVec3();
		var b = randomVec3();
		var m = MatrixTools.getDoubleCrossMat3(v);

		var exp = v.cross(v.cross(b));
		var res = b.clone();
		res.transform3x3(m);
		Check.vec3v(exp, res);
	}

	function testQR() {
		var m = random3x3();

		var q = new Matrix();
		var r = new Matrix();
		MatrixTools.qr(m, q, r);

		// Check r is upper triangular
		Assert.floatEquals(r._12, 0.0);
		Assert.floatEquals(r._13, 0.0);
		Assert.floatEquals(r._23, 0.0);

		var qr = new Matrix();
		qr.multCols(q, r);
		Check.mat3(m, qr);

		// Check q is orthonormal
		var qInv = q.clone();
		qInv.transpose();
		var qTest = new Matrix();
		qTest.multCols(qInv,q);
		Check.mat4(Matrix.I(), qTest);
	}

	function testEigenQR() {
		var mVals = [for (i in 0...16) 0.0];
		// Create a symmetric matrix via the same process
		// that a moment-of-inertia matrix would be generated
		for (i in 0...10) {
			var v = randomVec3();
			v.scale3(0.1);
			var mat = MatrixTools.getDoubleCrossMat3(v);
			var matVals = mat.getFloats();
			for (i in 0...16) {
				mVals[i] += matVals[i];
			}
		}
		var m = new Matrix();
		m.loadValues(mVals);

		var eVectMat = Matrix.I();
		var a = m.clone();

		var eVals = new Vector();
		MatrixTools.symmetricEigenQR(m, eVals, eVectMat);

		var a = new Matrix();
		a._11 = eVals.x;
		a._22 = eVals.y;
		a._33 = eVals.z;

		var maxEV = Math.max(Math.abs(eVals.x), Math.abs(eVals.y));
		maxEV = Math.max(maxEV, Math.abs(eVals.z));

		var eps = maxEV * 0.0001;

		var eVectTrans = eVectMat.clone();
		eVectTrans.transpose();

		// Test the eigen vectors are orthonormal
		var testQ = new Matrix();
		testQ.multCols(eVectTrans, eVectMat);
		Check.mat3(Matrix.I(), testQ);

		// Test that we can get back to m via the Eigen vector matrix
		var testA = new Matrix();
		testA.multCols(a, eVectTrans);
		testA.multCols(eVectMat, testA); // = Q * A * QT
		Check.mat3(m, testA, eps);

		// Test the eigen vector condition
		var eigenVects = MatrixTools.getColumns(eVectMat);
		var eigenVals = [eVals.x, eVals.y, eVals.z];
		for (i in 0...3) {
			var res = eigenVects[i].clone();
			res.transform(m);
			var resLen = res.length();
			var dot = res.dot3(eigenVects[i]);
			Assert.floatEquals(eigenVals[i], dot);
			Assert.floatEquals(Math.abs(eigenVals[i]), resLen, Math.abs(eigenVals[i]*0.0001));
		}
	}
}

