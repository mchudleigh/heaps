package hxd;

import h3d.Matrix;

class Debug {
    public static function assert(cond, ?message) {
        if (!cond) {
            throw (message != null) ? message : "assert failed";
        }
    }

	public static function floatNear(a: Float, b: Float, eps = 0.000001) {
		return Math.abs(a-b) < eps;
	}

	public static function matrixNear(a: Matrix, b: Matrix, eps = 0.000001) {
		var ret = true;
		ret = ret && Math.abs(a._11 - b._11) < eps;
		ret = ret && Math.abs(a._12 - b._12) < eps;
		ret = ret && Math.abs(a._13 - b._13) < eps;
		ret = ret && Math.abs(a._14 - b._14) < eps;

		ret = ret && Math.abs(a._21 - b._21) < eps;
		ret = ret && Math.abs(a._22 - b._22) < eps;
		ret = ret && Math.abs(a._23 - b._23) < eps;
		ret = ret && Math.abs(a._24 - b._24) < eps;

		ret = ret && Math.abs(a._31 - b._31) < eps;
		ret = ret && Math.abs(a._32 - b._32) < eps;
		ret = ret && Math.abs(a._33 - b._33) < eps;
		ret = ret && Math.abs(a._34 - b._34) < eps;

		ret = ret && Math.abs(a._41 - b._41) < eps;
		ret = ret && Math.abs(a._42 - b._42) < eps;
		ret = ret && Math.abs(a._43 - b._43) < eps;
		ret = ret && Math.abs(a._44 - b._44) < eps;

		return ret;
	}
}
