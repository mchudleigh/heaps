package;

import htst.CollisionTest;

class HeapsTestAll {
	public static function getTestList():Array<utest.Test> {
		return [
			new CollisionTest(),
		];
	}
	public static function main() {
		utest.UTest.run(getTestList());
	}
}
