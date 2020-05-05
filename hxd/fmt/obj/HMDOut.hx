package hxd.fmt.obj;

import hxd.fmt.hmd.Data;
import hxd.Debug;


class HMDOut {
	final filePath: String;
	var dataOut: haxe.io.BytesOutput;
	var obj: hxd.fmt.obj.Parser;
	var mats: Map<String, Parser.Material>;

	var vertSeqMap = new hxd.fmt.gltf.SeqIntMap();
	var vertData = [];
	var normData = [];
	var texData = [];
	var indices = [];
	var bounds = new h3d.col.Bounds();

	public function new(srcPath: String) {
		filePath = srcPath;
	}

	public function load(obj, mats) {
		this.obj = obj;
		this.mats = mats;
		bounds.empty();
	}

	private function handleFace(f: Parser.Face, hasTexCoords) {
		var inds = [];
		Debug.assert(f.verts.length == 3);

		for (v in f.verts) {
			Debug.assert(v.n != null);

			var vertInd = vertSeqMap.add([v.v, v.n, v.t]);
			if (vertInd == vertData.length) {
				// This index is at the end of the list
				// That signals it was not in the map before
				var vert = obj.verts[v.v];
				vertData.push(vert);
				bounds.addPos(vert.x, vert.y, vert.z);

				normData.push(obj.normals[v.n]);
				if (hasTexCoords)
					texData.push(obj.texCoords[v.t]);
			}
			inds.push(vertInd);
		}

		return inds;
	}

	public function toHMD(): Data {

		// Maintain a list of materials as they are referenced
		// the order will correspond to the order of the index array
		var matMap:Map<String,Int> = new Map();
		var matList = [];

		var hasTexCoords = obj.texCoords.length != 0;

		for (matName => faces in obj.faces) {
			var mat = mats[matName];
			if (mat == null) {
				throw 'Obj file references unknown material: $matName';
			}

			var matInd = matMap[matName];
			if (matInd == null) {
				matInd = matList.length;
				matMap[matName] = matInd;
				matList.push(mat);
				indices.push([]);
			}
			var matIndices = indices[matInd];

			for (f in faces) {
				var inds = handleFace(f, hasTexCoords);
				matIndices.push(inds[0]);
				matIndices.push(inds[1]);
				matIndices.push(inds[2]);
			}
		}

		Debug.assert(vertData.length == normData.length);
		if (hasTexCoords)
			Debug.assert(vertData.length == texData.length);

		dataOut = new haxe.io.BytesOutput();
		for (i in 0...vertData.length) {
			var v = vertData[i];
			dataOut.writeFloat(v.x);
			dataOut.writeFloat(v.y);
			dataOut.writeFloat(v.z);
			var n = normData[i];
			dataOut.writeFloat(n.x);
			dataOut.writeFloat(n.y);
			dataOut.writeFloat(n.z);
			if (hasTexCoords) {
				var t = texData[i];
				dataOut.writeFloat(t.x);
				dataOut.writeFloat(t.y);
			}
		}

		var indexPos = dataOut.length;
		for (matInds in indices) {
			for (ind in matInds) {
				dataOut.writeUInt16(ind);
			}
		}

		var geo = new Geometry();
		geo.props = null;
		geo.vertexCount = vertData.length;
		geo.vertexStride = hasTexCoords ? 8 : 6;

		geo.vertexFormat = [];
		geo.vertexFormat.push(new GeometryFormat("position", DVec3));
		geo.vertexFormat.push(new GeometryFormat("normal", DVec3));
		if (hasTexCoords)
			geo.vertexFormat.push(new GeometryFormat("uv", DVec2));

		geo.vertexPosition = 0;
		geo.indexCounts = Lambda.map(indices, (x) -> x.length);
		geo.indexPosition = indexPos;
		geo.bounds = bounds.clone();

		var pos = new Position();
		pos.setIdent();

		var model = new Model();
		model.name = obj.name;
		model.props = null;
		model.parent = -1;
		model.follow = null;
		model.position = pos;
		model.geometry = 0;
		model.materials = [for (i in 0...matList.length) i];
		model.skin = null;

		var materials = [];
		for (mat in matList) {
			var hMat = new Material();
			hMat.name = mat.name;
			hMat.diffuseTexture = mat.diffTex;
			hMat.blendMode = None;
			materials.push(hMat);
		}

		var data = new Data();

		#if hmd_version
		data.version = Std.parseInt(#if macro haxe.macro.Context.definedValue("hmd_version") #else haxe.macro.Compiler.getDefine("hmd_version") #end);
		#else
		data.version = Data.CURRENT_VERSION;
		#end
		data.props = null;
		data.geometries = [geo];
		data.materials = materials;
		data.models = [model];
		data.animations = [];
		data.dataPosition = 0;

		// var dumpString = hxd.fmt.hmd.Dump.toString(data);
		// trace(dumpString);

		data.data = dataOut.getBytes();

		return data;
	}
}
