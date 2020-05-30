package;

import htst.CollisionTest;
import htst.HeapTest;

class HeapsTestAll {
	public static function getTestList():Array<utest.Test> {
		return [
			new CollisionTest(),
			new HeapTest(),
		];
	}
	public static function main() {
		utest.UTest.run(getTestList());
	}
}
