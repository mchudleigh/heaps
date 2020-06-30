package hxd;

class Debug {
    public static function assert(cond, ?message) {
        if (!cond) {
            throw (message != null) ? message : "assert failed";
        }
    }

	public static function floatNear(a: Float, b: Float, eps = 0.000001) {
		return Math.abs(a-b) < eps;
	}
}
