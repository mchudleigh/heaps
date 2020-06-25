package;

import htst.CollisionTest;
import htst.MathTest;
import htst.MatrixTest;
import htst.HeapTest;
import htst.PhysicsTest;

class HeapsTestAll {
	public static function getTestList():Array<utest.Test> {
		return [
			new CollisionTest(),
			new MathTest(),
			new MatrixTest(),
			new HeapTest(),
			new PhysicsTest(),
		];
	}
	public static function main() {
		utest.UTest.run(getTestList());
	}
}
