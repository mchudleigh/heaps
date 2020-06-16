package htst;

import utest.Assert;

import h3d.Quat;
import h3d.Vector;

class Check {
	public static function quat(x, y, z, w, q:Quat, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		Assert.floatEquals(x, q.x, eps, 'X component wrong. Expected: $x Got: ${q.x}', pos);
		Assert.floatEquals(y, q.y, eps, 'Y component wrong. Expected: $y Got: ${q.y}', pos);
		Assert.floatEquals(z, q.z, eps, 'Z component wrong. Expected: $z Got: ${q.z}', pos);
		Assert.floatEquals(w, q.w, eps, 'W component wrong. Expected: $w Got: ${q.w}', pos);

		return
			Math.abs(x-q.x) > eps ||
			Math.abs(y-q.y) > eps ||
			Math.abs(z-q.z) > eps ||
			Math.abs(w-q.w) > eps;
	}

	public static function vec4(x, y, z, w, v:Vector, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		Assert.floatEquals(x, v.x, eps, 'X component wrong. Expected: $x Got: ${v.x}', pos);
		Assert.floatEquals(y, v.y, eps, 'Y component wrong. Expected: $y Got: ${v.y}', pos);
		Assert.floatEquals(z, v.z, eps, 'Z component wrong. Expected: $z Got: ${v.z}', pos);
		Assert.floatEquals(w, v.w, eps, 'W component wrong. Expected: $w Got: ${v.w}', pos);

		return
			Math.abs(x-v.x) > eps ||
			Math.abs(y-v.y) > eps ||
			Math.abs(z-v.z) > eps ||
			Math.abs(w-v.w) > eps;
	}

	public static function vec3(x, y, z, v:Vector, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		Assert.floatEquals(x, v.x, eps, 'X component wrong. Expected: $x Got: ${v.x}', pos);
		Assert.floatEquals(y, v.y, eps, 'Y component wrong. Expected: $y Got: ${v.y}', pos);
		Assert.floatEquals(z, v.z, eps, 'Z component wrong. Expected: $z Got: ${v.z}', pos);

		return
			Math.abs(x-v.x) > eps ||
			Math.abs(y-v.y) > eps ||
			Math.abs(z-v.z) > eps;
	}

	public static function point(x, y, z, p, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		Assert.floatEquals(x, p.x, eps, 'X component wrong. Expected: $x Got: ${p.x}', pos);
		Assert.floatEquals(y, p.y, eps, 'Y component wrong. Expected: $y Got: ${p.y}', pos);
		Assert.floatEquals(z, p.z, eps, 'Z component wrong. Expected: $z Got: ${p.z}', pos);

		return Math.abs(x-p.x) > eps ||Math.abs(y-p.y) > eps ||Math.abs(z-p.z) > eps;
	}
	public static function floatArray(exp:Array<Float>, val:Array<Float>, ?pos:haxe.PosInfos) {
		Assert.equals(exp.length, val.length,
			 'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			Assert.floatEquals(exp[i], val[i],
				'Float array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
		}
	}
	public static function array(exp:Array<Dynamic>, val:Array<Dynamic>, ?pos:haxe.PosInfos) {
		Assert.equals(exp.length, val.length,
			'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			Assert.equals(exp[i], val[i],
				'Array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
		}
	}

	public static function arrayOptions(exp:Array<Dynamic>, val:Array<Dynamic>, ?pos:haxe.PosInfos) {
		// Scratch
		var arrayClass = Type.resolveClass("Array");

		Assert.equals(exp.length, val.length,
			'Array length wrong. Expected: ${exp.length} Got: ${val.length}', pos);
		var minLen = Std.int(Math.min(exp.length, val.length));
		for(i in 0...minLen) {
			var expType = Type.getClass(exp[i]);
			if (expType == arrayClass) {
				// This is a list of possible options. Check that one matches
				var optionList = cast (exp[i], Array<Dynamic>);
				var found = false;
				for (o in optionList) {
					if (val[i] == o) found = true;
				}
				Assert.isTrue(found,
					'Option failure in array at element $i', pos);
			} else {
			Assert.equals(exp[i], val[i],
				'Array element mismatch at $i. Expected: ${exp[i]} Got: ${val[i]}', pos);
			}
		}
	}

}
