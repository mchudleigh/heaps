package htst;

import utest.Assert;

import h3d.Quat;
import h3d.Vector;
import h3d.Matrix;

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
	public static function vec3v(exp, v:Vector, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		return vec3(exp.x, exp.y, exp.z, v, eps, pos);
	}
	public static function vec4v(exp, v:Vector, eps = 0.00001, ?pos:haxe.PosInfos):Bool {
		return vec4(exp.x, exp.y, exp.z, exp.w, v, eps, pos);
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

	public static function mat4(exp:Matrix, val:Matrix, eps = 0.00001, ?pos:haxe.PosInfos) {
		Assert.floatEquals(exp._11, val._11, eps, '[1,1] component wrong. Expected: ${exp._11} Got: ${val._11}', pos);
		Assert.floatEquals(exp._12, val._12, eps, '[1,2] component wrong. Expected: ${exp._12} Got: ${val._12}', pos);
		Assert.floatEquals(exp._13, val._13, eps, '[1,3] component wrong. Expected: ${exp._13} Got: ${val._13}', pos);
		Assert.floatEquals(exp._14, val._14, eps, '[1,4] component wrong. Expected: ${exp._14} Got: ${val._14}', pos);

		Assert.floatEquals(exp._21, val._21, eps, '[2,1] component wrong. Expected: ${exp._21} Got: ${val._21}', pos);
		Assert.floatEquals(exp._22, val._22, eps, '[2,2] component wrong. Expected: ${exp._22} Got: ${val._22}', pos);
		Assert.floatEquals(exp._23, val._23, eps, '[2,3] component wrong. Expected: ${exp._23} Got: ${val._23}', pos);
		Assert.floatEquals(exp._24, val._24, eps, '[2,4] component wrong. Expected: ${exp._24} Got: ${val._24}', pos);

		Assert.floatEquals(exp._31, val._31, eps, '[3,1] component wrong. Expected: ${exp._31} Got: ${val._31}', pos);
		Assert.floatEquals(exp._32, val._32, eps, '[3,2] component wrong. Expected: ${exp._32} Got: ${val._32}', pos);
		Assert.floatEquals(exp._33, val._33, eps, '[3,3] component wrong. Expected: ${exp._33} Got: ${val._33}', pos);
		Assert.floatEquals(exp._34, val._34, eps, '[3,4] component wrong. Expected: ${exp._34} Got: ${val._34}', pos);

		Assert.floatEquals(exp._41, val._41, eps, '[4,1] component wrong. Expected: ${exp._41} Got: ${val._41}', pos);
		Assert.floatEquals(exp._42, val._42, eps, '[4,2] component wrong. Expected: ${exp._42} Got: ${val._42}', pos);
		Assert.floatEquals(exp._43, val._43, eps, '[4,3] component wrong. Expected: ${exp._43} Got: ${val._43}', pos);
		Assert.floatEquals(exp._44, val._44, eps, '[4,4] component wrong. Expected: ${exp._44} Got: ${val._44}', pos);

	}

	public static function mat3(exp:Matrix, val:Matrix, eps = 0.00001, ?pos:haxe.PosInfos) {
		Assert.floatEquals(exp._11, val._11, eps, '[1,1] component wrong. Expected: ${exp._11} Got: ${val._11}', pos);
		Assert.floatEquals(exp._12, val._12, eps, '[1,2] component wrong. Expected: ${exp._12} Got: ${val._12}', pos);
		Assert.floatEquals(exp._13, val._13, eps, '[1,3] component wrong. Expected: ${exp._13} Got: ${val._13}', pos);

		Assert.floatEquals(exp._21, val._21, eps, '[2,1] component wrong. Expected: ${exp._21} Got: ${val._21}', pos);
		Assert.floatEquals(exp._22, val._22, eps, '[2,2] component wrong. Expected: ${exp._22} Got: ${val._22}', pos);
		Assert.floatEquals(exp._23, val._23, eps, '[2,3] component wrong. Expected: ${exp._23} Got: ${val._23}', pos);

		Assert.floatEquals(exp._31, val._31, eps, '[3,1] component wrong. Expected: ${exp._31} Got: ${val._31}', pos);
		Assert.floatEquals(exp._32, val._32, eps, '[3,2] component wrong. Expected: ${exp._32} Got: ${val._32}', pos);
		Assert.floatEquals(exp._33, val._33, eps, '[3,3] component wrong. Expected: ${exp._33} Got: ${val._33}', pos);

	}


}
