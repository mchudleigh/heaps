package hxd;

class Debug {
    public static function assert(cond, ?message) {
        if (!cond) {
            throw (message != null) ? message : "assert failed";
        }
    }
}
