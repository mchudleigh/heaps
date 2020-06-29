package h3d;

import hxd.Debug;

class MatrixTools {

	// Generate a 4x4 Householder reflection matrix from a normal vector
	public static function hhRef4(n: Vector, out:Matrix) {
		out._11 = 1 - 2*(n.x*n.x);
		out._22 = 1 - 2*(n.y*n.y);
		out._33 = 1 - 2*(n.z*n.z);
		out._44 = 1 - 2*(n.w*n.w);

		out._12 = -2*(n.x*n.y);
		out._21 = out._12;
		out._13 = -2*(n.x*n.z);
		out._31 = out._13;
		out._14 = -2*(n.x*n.w);
		out._41 = out._14;

		out._23 = -2*(n.y*n.z);
		out._32 = out._23;
		out._24 = -2*(n.y*n.w);
		out._42 = out._24;

		out._34 = -2*(n.z*n.w);
		out._43 = out._34;
	}

	public static function hhRef3(n: Vector, out:Matrix) {
		out._11 = 1 - 2*(n.x*n.x);
		out._22 = 1 - 2*(n.y*n.y);
		out._33 = 1 - 2*(n.z*n.z);

		out._12 = -2*(n.x*n.y);
		out._21 = out._12;
		out._13 = -2*(n.x*n.z);
		out._31 = out._13;

		out._23 = -2*(n.y*n.z);
		out._32 = out._23;

		out._14 = 0.0;
		out._24 = 0.0;
		out._34 = 0.0;

		out._41 = 0.0;
		out._42 = 0.0;
		out._43 = 0.0;

		out._44 = 1.0;
	}

	// Perform a 3x3 QR decomp  of 'm' into the provided 'output' parameters
	public static function qr(m:Matrix, qOut:Matrix, rOut: Matrix) {
		var cols = getColumns(m);

		var alpha0 = cols[0].length();
		var v0 = cols[0].clone();
		if (v0.x > 0)
			v0.x -= alpha0;
		else
			v0.x += alpha0;

		v0.normalize();
		var q0 = new Matrix();
		hhRef3(v0, q0);

		var r0 = new Matrix();
		r0.multCols(q0, m);

		var v1y = r0._22;
		var v1z = r0._23;
		var alpha1 = Math.sqrt(v1y*v1y+v1z*v1z);
		if (v1y > 0)
			v1y -= alpha1;
		else
			v1y += alpha1;
		var v1Len = Math.sqrt(v1y*v1y+v1z*v1z);
		v1y = v1y/v1Len;
		v1z = v1z/v1Len;
		// Hand roll a 2x2 householder matrix
		var q1 = Matrix.I();
		q1._22 -= 2*v1y*v1y;
		q1._23 -= 2*v1y*v1z;
		q1._32 -= 2*v1y*v1z;
		q1._33 -= 2*v1z*v1z;

		var r1 = new Matrix();
		r1.multCols(q1, r0);

		rOut.load(r1);
		qOut.multCols(q1, q0);
		qOut.transpose();

	}

	// Perform an eigen value decomposition of a symmetric 3x3 matrix
	public static function symmetricEigenQR(m: Matrix, valuesOut: Vector, vectorsOut: Matrix) {

		Debug.assert(m.isSymmetric3());
		var q = new Matrix();
		var r = new Matrix();
		vectorsOut.identity();
		var a = m.clone();

		var numLoops = 0;
		while (numLoops < 100) {
			qr(a, q, r);
			a.multCols(r,q);
			// accumulate in the output
			vectorsOut.multCols(vectorsOut, q);

			var maxEV = Math.max(Math.abs(a._11), Math.abs(a._22));
			maxEV = Math.max(maxEV, Math.abs(a._33));
			var eps = maxEV * 0.0001;

			// Test convergence
			var conv =
				Math.abs(a._12) < eps &&
				Math.abs(a._13) < eps &&

				Math.abs(a._21) < eps &&
				Math.abs(a._23) < eps &&

				Math.abs(a._31) < eps &&
				Math.abs(a._32) < eps;

			if (conv) break;

			++numLoops;
		}

		valuesOut.x = a._11;
		valuesOut.y = a._22;
		valuesOut.z = a._33;

		return numLoops;
	}

	// convert this matrix into an array of column vectors
	public static function getColumns(m:Matrix):Array<Vector> {
		var ret = [];
		var vals = m.getFloats();
		for (i in 0...4) {
			var v = new Vector();
			v.x = vals[i*4+0];
			v.y = vals[i*4+1];
			v.z = vals[i*4+2];
			v.w = vals[i*4+3];
			ret.push(v);
		}
		return ret;
	}

	// Returns a matrix that when applied to "crossing" by v twice
	// ie: return M such that Mb = v x (v x b) (in 3 dimensions)
	public static function getDoubleCrossMat3(v: Vector): Matrix {
		var ret = Matrix.I();
		var x = v.x; var y = v.y; var z = v.z;
		ret._11 = -1.0*(y*y + z*z);
		ret._22 = -1.0*(x*x + z*z);
		ret._33 = -1.0*(x*x + y*y);
		ret._12 = x*y;
		ret._21 = x*y;

		ret._13 = x*z;
		ret._31 = x*z;

		ret._23 = y*z;
		ret._32 = y*z;

		return ret;
	}
}
