package hxd.fmt.gltf;

import h3d.Quat;
import h3d.Vector;
import h3d.col.Bounds;
import hxd.fmt.hmd.Data;

import hxd.Debug;

import hxd.fmt.gltf.Data;


class HMDOut {

	var gltfData: Data;
	var name: String;
	var relDir: String;

	public function new(name:String, relDir:String, data: Data) {
		this.name = name;
		this.relDir = relDir;
		this.gltfData = data;
	}

	public function toHMD():hxd.fmt.hmd.Data {
		var outBytes = new haxe.io.BytesOutput();

		// Emit the geometry

		// Emit unique combinations of accessors
		// as a single buffer to save data
		var geoMap = new SeqIntMap();
		for (mesh in gltfData.meshes) {
			for (prim in mesh.primitives) {
				geoMap.add(prim.accList);
			}
		}

		// Map from the entries in geoMap to
		// data positions
		var dataPos = [];
		var bounds = [];

		// Emit one HMD geometry per unique primitive combo
		for (i in 0...geoMap.count) {
			dataPos.push(outBytes.length);
			var bb = new Bounds();
			bb.empty();
			bounds.push(bb);

			var accList = geoMap.getList(i);
			var hasNorm = accList[NOR] != -1;
			var hasTex = accList[TEX] != -1;
			var hasJoints = accList[JOINTS] != -1;
			var hasWeights = accList[WEIGHTS] != -1;
			var hasIndices = accList[INDICES] != -1;

			// We do not support generating normals on models that use indices (yet)
			Debug.assert(hasNorm || !hasIndices);

			Debug.assert(hasJoints == hasWeights);

			var posAcc = gltfData.accData[accList[POS]];

			var genNormals = null;
			if (!hasNorm) {
				genNormals = generateNormals(posAcc);
			}

			var norAcc = gltfData.accData[accList[NOR]];
			var texAcc = gltfData.accData[accList[TEX]];
			var jointAcc = hasJoints ? gltfData.accData[accList[JOINTS]] : null;
			var weightAcc = hasWeights ? gltfData.accData[accList[WEIGHTS]] : null;

			for (i in 0...posAcc.count) {
				// Position data
				var x = Util.getFloat(gltfData, posAcc, i, 0);
				outBytes.writeFloat(x);
				var y = Util.getFloat(gltfData, posAcc, i, 1);
				outBytes.writeFloat(y);
				var z = Util.getFloat(gltfData, posAcc, i, 2);
				outBytes.writeFloat(z);
				bb.addPos(x, y, z);

				// Normal data
				if (hasNorm) {
					outBytes.writeFloat(Util.getFloat(gltfData, norAcc, i, 0));
					outBytes.writeFloat(Util.getFloat(gltfData, norAcc, i, 1));
					outBytes.writeFloat(Util.getFloat(gltfData, norAcc, i, 2));
				} else {
					var norm = genNormals[Std.int(i/3)];
					outBytes.writeFloat(norm.x);
					outBytes.writeFloat(norm.y);
					outBytes.writeFloat(norm.z);
				}

				// Tex coord data
				if (hasTex) {
					outBytes.writeFloat(Util.getFloat(gltfData, texAcc, i, 0));
					outBytes.writeFloat(Util.getFloat(gltfData, texAcc, i, 1));
				} else {
					outBytes.writeFloat(0.5);
					outBytes.writeFloat(0.5);
				}

				// Note: Heaps currently only supports up to
				// 3 bones influencing a vertex at once
				// therefore drop the 4th index and weight
				// and renormalize the weights

				if (hasJoints) {
					for (jInd in 0...3) {
						var joint = Util.getUShort(gltfData, jointAcc, i, jInd);
						Debug.assert(joint >= 0);
						outBytes.writeByte(joint);
					}
					outBytes.writeByte(0);
				}
				if (hasWeights) {
					var weights =[];
					var sum = 0.0;
					for (wInd in 0...3) {
						var wVal = Util.getFloat(gltfData, weightAcc, i, wInd);
						Debug.assert(!Math.isNaN(wVal));
						weights.push(wVal);
						sum+=wVal;
					}

					outBytes.writeFloat(weights[0]/sum);
					outBytes.writeFloat(weights[1]/sum);
					outBytes.writeFloat(weights[2]/sum);
					outBytes.writeFloat(0);
				}
			}
		}

		// Find the unique combination of accessor lists in each
		// mesh. This will map on to the HMD geometry concept
		var meshAccLists:Array<Array<Int>> = [];
		for (mesh in gltfData.meshes) {
			var accs = Lambda.map(mesh.primitives, (prim) -> geoMap.add(prim.accList));
			accs.sort((a, b) -> a - b);
			var uniqueAccs = [];
			var last = -1;
			for (a in accs) {
				if (a != last) {
					uniqueAccs.push(a);
					last = a;
				}
			}
			meshAccLists.push(uniqueAccs);
		}

		var geos = [];
		var geoMaterials:Array<Array<Int>> = [];

		// Generate a geometry for each mesh-accessor
		// Also retain the materials used
		var meshToGeoMap:Array<Array<Int>> = [];
		for (meshInd in 0...gltfData.meshes.length) {
			var meshGeoList = [];
			meshToGeoMap.push(meshGeoList);

			var accList = meshAccLists[meshInd];
			for (accSet in accList) {
				var accessors = geoMap.getList(accSet);
				var posAcc = gltfData.accData[accessors[0]];

				var geo = new Geometry();
				var geoMats = [];
				meshGeoList.push(geos.length);
				geos.push(geo);
				geoMaterials.push(geoMats);
				geo.props = null;
				geo.vertexCount = posAcc.count;
				geo.vertexStride = 8;

				geo.vertexFormat = [];
				geo.vertexFormat.push(new GeometryFormat("position", DVec3));
				geo.vertexFormat.push(new GeometryFormat("normal", DVec3));
				geo.vertexFormat.push(new GeometryFormat("uv", DVec2));
				geo.vertexPosition = dataPos[accSet];
				geo.bounds = bounds[accSet];

				if (accessors[3] != -1) {
					// Has joint and weight data
					geo.vertexStride += 5;
					geo.vertexFormat.push(new GeometryFormat("indexes", DBytes4));
					geo.vertexFormat.push(new GeometryFormat("weights", DVec4));
				}

				var mesh = gltfData.meshes[meshInd];
				var indexList = [];
				// Iterate the primitives and add indices for this geo
				for (prim in mesh.primitives) {
					var primAccInd = geoMap.add(prim.accList);
					if (accSet != primAccInd)
						continue; // Different geo

					var matInd = geoMats.indexOf(prim.matInd);
					if (matInd == -1) {
						// First use of this mat
						matInd = geoMats.length;
						geoMats.push(prim.matInd);
						indexList.push([]);
					}
					// Fill the index list
					if (prim.indices != null) {
						var iList = indexList[matInd];
						var indexAcc = gltfData.accData[prim.indices];
						for (i in 0...indexAcc.count) {
							iList.push(Util.getIndex(gltfData, indexAcc, i));
						}
					} else {
						indexList[matInd] = [for (i in 0...geo.vertexCount) i];
					}
				}

				// Emit the indices
				geo.indexPosition = outBytes.length;
				geo.indexCounts = Lambda.map(indexList, (x) -> x.length);
				for (inds in indexList) {
					for (i in inds) {
						outBytes.writeUInt16(i);
					}
				}
			}
		}

		var inlineImages = [];
		var materials = [];
		for (matInd in 0...gltfData.mats.length) {
			var mat = gltfData.mats[matInd];
			var hMat = new hxd.fmt.hmd.Material();
			hMat.name = mat.name;

			if (mat.colorTex != null) {
				switch(mat.colorTex) {
					case File(fileName):
						hMat.diffuseTexture = relDir + fileName;
					case Buffer(buff, pos, len, ext): {
						inlineImages.push(
							{ buff:buff, pos:pos, len:len, ext:ext, mat:matInd });
					}
				}
			} else if (mat.color != null) {
				hMat.diffuseTexture = h3d.mat.Texture.toColorString(mat.color);
			} else {
				hMat.diffuseTexture = h3d.mat.Texture.toColorString(0);
			}
			hMat.blendMode = None;
			materials.push(hMat);
		}

		var identPos = new hxd.fmt.hmd.Position();
		identPos.setIdent();

		var models = [];
		var rootModel = new Model();
		rootModel.name = this.name;
		rootModel.props = null;
		rootModel.parent = -1;
		rootModel.follow = null;
		rootModel.position = identPos;
		rootModel.skin = null;
		rootModel.geometry = -1;
		rootModel.materials = null;
		models[0] = rootModel;

		var nextOutID = 1;
		for (n in gltfData.nodes) {
			// Mark the slot the node will be put into
			// while skipping over joints
			if (!n.isJoint) {
				n.outputID = nextOutID++;
			}
		}

		for (i in 0...gltfData.nodes.length) {
			// Sanity check
			var node = gltfData.nodes[i];
			Debug.assert(node.nodeInd == i);
			if (node.isJoint)
				continue;

			var model = new Model();
			model.name = node.name;
			model.props = null;
			model.parent = node.parent != null ? node.parent.outputID: 0;
			model.follow = null;
			model.position = nodeToPos(node);
			model.skin = null;
			if (node.mesh != null) {
				if (node.skin != null) {
					model.skin = buildSkin(gltfData.skins[node.skin], node.name);
					//model.skin = null;
				}

				var geoList = meshToGeoMap[node.mesh];
				if(geoList.length == 1) {
					// We can put the single geometry in this node
					model.geometry = geoList[0];
					model.materials = geoMaterials[geoList[0]];
				} else {
					model.geometry = -1;
					model.materials = null;
					// We need to generate a model per primitive
					for (geoInd in geoList) {
						var primModel = new Model();
						primModel.name = gltfData.meshes[node.mesh].name;
						primModel.props = null;
						primModel.parent = node.outputID;
						primModel.position = identPos;
						primModel.follow = null;
						primModel.skin = null;
						primModel.geometry = geoInd;
						primModel.materials = geoMaterials[geoInd];
						models[nextOutID++] = primModel;
					}
				}

			} else {
				model.geometry = -1;
				model.materials = null;
			}
			models[node.outputID] = model;
		}

		// Populate animation information and fill data
		var anims = [];
		for (animData in gltfData.animations) {
			var anim = new hxd.fmt.hmd.Data.Animation();
			anim.name = animData.name;
			anim.props = null;
			anim.frames = animData.numFrames;
			anim.sampling = Data.SAMPLE_RATE;
			anim.speed = 1.0;
			anim.loop = false;
			anim.objects = [];
			for (curveData in animData.curves) {
				var animObject = new hxd.fmt.hmd.Data.AnimationObject();
				animObject.name = curveData.targetName;

				if (curveData.transValues != null) {
					animObject.flags.set(HasPosition);
				}
				if (curveData.rotValues != null) {
					animObject.flags.set(HasRotation);
				}
				if (curveData.scaleValues != null) {
					animObject.flags.set(HasScale);
				}
				anim.objects.push(animObject);
			}
			// Fill in the animation data
			anim.dataPosition = outBytes.length;
			for (f in 0...anim.frames) {
				for (curve in animData.curves) {
					if (curve.transValues != null) {
						outBytes.writeFloat(curve.transValues[f*3+0]);
						outBytes.writeFloat(curve.transValues[f*3+1]);
						outBytes.writeFloat(curve.transValues[f*3+2]);
					}
					if (curve.rotValues != null) {
						var quat = new Quat(
							curve.rotValues[f*4+0],
							curve.rotValues[f*4+1],
							curve.rotValues[f*4+2],
							curve.rotValues[f*4+3]);
						var qLength = quat.length();
						Debug.assert(Math.abs(qLength-1.0) < 0.2);
						quat.normalize();
						if (quat.w < 0) {
							quat.w*= -1;
							quat.x*= -1;
							quat.y*= -1;
							quat.z*= -1;
						}
						outBytes.writeFloat(quat.x);
						outBytes.writeFloat(quat.y);
						outBytes.writeFloat(quat.z);
					}
					if (curve.scaleValues != null) {
						outBytes.writeFloat(curve.scaleValues[f*3+0]);
						outBytes.writeFloat(curve.scaleValues[f*3+1]);
						outBytes.writeFloat(curve.scaleValues[f*3+2]);
					}
				}
			}
			anims.push(anim);

		}

		// Append any inline images to the binary data
		for (img in inlineImages) {
			// Generate a new texture string using the relative-texture format
			var mat = materials[img.mat];
			mat.diffuseTexture = '${img.ext}@${outBytes.length}--${img.len}';

			var imageBytes = gltfData.bufferData[img.buff].sub(img.pos, img.len);
			outBytes.writeBytes(imageBytes, 0, img.len);
		}

		var ret = new hxd.fmt.hmd.Data();
		#if hmd_version
		ret.version = Std.parseInt(#if macro haxe.macro.Context.definedValue("hmd_version") #else haxe.macro.Compiler.getDefine("hmd_version") #end);
		#else
		ret.version = hxd.fmt.hmd.Data.CURRENT_VERSION;
		#end
		ret.props = null;
		ret.materials = materials;
		ret.geometries = geos;
		ret.models = models;
		ret.animations = anims;
		ret.dataPosition = 0;

		ret.data = outBytes.getBytes();

		return ret;
	}

	function buildSkin(skin:SkinData, nodeName): hxd.fmt.hmd.Data.Skin {
		var ret = new hxd.fmt.hmd.Data.Skin();
		ret.name = (skin.skeleton != null ? gltfData.nodes[skin.skeleton].name : nodeName) + "_skin";
		ret.props = null;
		ret.split = null;
		ret.joints = [];
		for (i in 0...skin.joints.length) {
			var jInd = skin.joints[i];
			var sj = new hxd.fmt.hmd.Data.SkinJoint();
			var node = gltfData.nodes[jInd];
			sj.name = node.name;
			sj.props = null;
			sj.position = nodeToPos(node);
			sj.parent = skin.joints.indexOf(node.parent.nodeInd);
			sj.bind = i;

			// Get invBindMatrix
			var invBindMat = Util.getMatrix(gltfData,gltfData.accData[skin.invBindMatAcc], i);
			sj.transpos = Position.fromMatrix(invBindMat);
			// Ensure this matrix converted to a 'Position' correctly
			var testMat = sj.transpos.toMatrix();
			//var testPos = Position.fromMatrix(testMat);
			Debug.assert(Util.matNear(invBindMat, testMat));

			ret.joints.push(sj);
		}


		return ret;
	}

	function generateNormals(posAcc:BuffAccess) : Array<Vector> {
		Debug.assert(posAcc.count % 3 == 0);
		var numTris = Std.int(posAcc.count / 3);
		var ret = [];
		for (i in 0...numTris) {

			var ps = [];
			for (p in 0...3) {
				ps.push(new Vector(
					Util.getFloat(gltfData, posAcc, i*3+p,0),
					Util.getFloat(gltfData, posAcc, i*3+p,1),
					Util.getFloat(gltfData, posAcc, i*3+p,2)));
			}
			var d0 = ps[1].sub(ps[0]);
			var d1 = ps[2].sub(ps[1]);
			ret.push(d0.cross(d1));
		}
		return ret;

	}
	function nodeToPos(node: NodeData): Position {
		var ret = new Position();
		if (node.trans != null) {
			ret.x = node.trans.x;
			ret.y = node.trans.y;
			ret.z = node.trans.z;
		} else {
			ret.x = 0.0;
			ret.y = 0.0;
			ret.z = 0.0;
		}
		if (node.rot != null) {
			var posW = node.rot.w > 0.0;
			ret.qx = node.rot.x * (posW?1.0:-1.0);
			ret.qy = node.rot.y * (posW?1.0:-1.0);
			ret.qz = node.rot.z * (posW?1.0:-1.0);
		} else {
			ret.qx = 0.0;
			ret.qy = 0.0;
			ret.qz = 0.0;
		}
		if (node.scale != null) {
			ret.sx = node.scale.x;
			ret.sy = node.scale.y;
			ret.sz = node.scale.z;
		} else {
			ret.sx = 1.0;
			ret.sy = 1.0;
			ret.sz = 1.0;
		}
		return ret;
	}

	public static function emitHMD(name:String, relDir:String, data: Data) {
		var out = new HMDOut(name, relDir,data);
		return out.toHMD();
	}
}
