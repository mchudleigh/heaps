package hxd.fmt.gltf;

import hxd.fmt.gltf.GLTFData;

class Util {

	// retrieve the float value from an accessor for a specified
	// entry (eg: vertex) and component (eg: x)
	public inline static function getFloat(data: GLTFData, buffAcc:BuffAccess, entry:Int, comp:Int):Float {
		var buff = data.bufferData[buffAcc.bufferInd];
		Debug.assert(buffAcc.compSize == 4);
		var pos = buffAcc.offset + (entry * buffAcc.stride) + comp * 4;
		Debug.assert(pos < buffAcc.maxPos);
		return buff.getFloat(pos);
	}

	public inline static function getUShort(data: GLTFData, buffAcc:BuffAccess, entry:Int, comp:Int):Int {
		var buff = data.bufferData[buffAcc.bufferInd];
		Debug.assert(buffAcc.compSize == 2);
		var pos = buffAcc.offset + (entry * buffAcc.stride) + comp * 2;
		Debug.assert(pos < buffAcc.maxPos);
		return buff.getUInt16(pos);
	}

	public static function getMatrix(data: GLTFData, buffAcc:BuffAccess, entry:Int): h3d.Matrix {
		var floats = [];
		for (i in 0...16) {
			floats[i] = getFloat(data, buffAcc, entry, i);
		}
		var ret = new h3d.Matrix();
		ret._11 = floats[ 0];
		ret._12 = floats[ 1];
		ret._13 = floats[ 2];
		ret._14 = floats[ 3];

		ret._21 = floats[ 4];
		ret._22 = floats[ 5];
		ret._23 = floats[ 6];
		ret._24 = floats[ 7];

		ret._31 = floats[ 8];
		ret._32 = floats[ 9];
		ret._33 = floats[10];
		ret._34 = floats[11];

		ret._41 = floats[12];
		ret._42 = floats[13];
		ret._43 = floats[14];
		ret._44 = floats[15];
		return ret;
	}

	// retrieve the scalar int from a buffer access
	public static inline function getIndex(data: GLTFData, buffAcc:BuffAccess, entry:Int):Int {
		var buff = data.bufferData[buffAcc.bufferInd];
		var pos = buffAcc.offset + (entry * buffAcc.stride);
		Debug.assert(pos < buffAcc.maxPos);
		switch (buffAcc.compSize) {
			case 1:
				return buff.get(pos);
			case 2:
				return buff.getUInt16(pos);
			case 4:
				return buff.getInt32(pos);
			default:
				throw 'Unknown index type. Component size: ${buffAcc.compSize}';
		}
	}

	public static function matNear(matA:h3d.Matrix, matB:h3d.Matrix):Bool {
		var ret = true;
		ret = ret && Math.abs(matA._11 - matB._11) < 0.0001;
		ret = ret && Math.abs(matA._12 - matB._12) < 0.0001;
		ret = ret && Math.abs(matA._13 - matB._13) < 0.0001;
		ret = ret && Math.abs(matA._14 - matB._14) < 0.0001;

		ret = ret && Math.abs(matA._21 - matB._21) < 0.0001;
		ret = ret && Math.abs(matA._22 - matB._22) < 0.0001;
		ret = ret && Math.abs(matA._23 - matB._23) < 0.0001;
		ret = ret && Math.abs(matA._24 - matB._24) < 0.0001;

		ret = ret && Math.abs(matA._31 - matB._31) < 0.0001;
		ret = ret && Math.abs(matA._32 - matB._32) < 0.0001;
		ret = ret && Math.abs(matA._33 - matB._33) < 0.0001;
		ret = ret && Math.abs(matA._34 - matB._34) < 0.0001;

		ret = ret && Math.abs(matA._41 - matB._41) < 0.0001;
		ret = ret && Math.abs(matA._42 - matB._42) < 0.0001;
		ret = ret && Math.abs(matA._43 - matB._43) < 0.0001;
		ret = ret && Math.abs(matA._44 - matB._44) < 0.0001;

		return ret;
	}

}
