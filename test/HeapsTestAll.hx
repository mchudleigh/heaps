package;

import htst.CollisionTest;
import htst.MathTest;
import htst.MatrixTest;
import htst.HeapTest;

class HeapsTestAll {
	public static function getTestList():Array<utest.Test> {
		return [
			new CollisionTest(),
			new MathTest(),
			new MatrixTest(),
			new HeapTest(),
		];
	}
	public static function main() {
		utest.UTest.run(getTestList());
	}
}
