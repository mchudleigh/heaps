package hxd.fmt.gltf;

import h3d.Quat;
import haxe.EnumFlags;
import h3d.col.Bounds;
import hxd.fmt.hmd.Data;
import hxd.fmt.gltf.SeqIntMap;
import h3d.Vector;
import haxe.Json;
import hxd.fmt.hmd.Data;

private enum abstract ComponentType(Int) {
	var BYTE = 5120;
	var UNSIGNED_BYTE = 5121;
	var SHORT = 5122;
	var UNSIGNED_SHORT = 5123;
	// Oddly GLTF does not seem to allow signed INTs
	var UNSIGNED_INT = 5125;
	var FLOAT = 5126;
}

private enum abstract AccessorType(String) {
	var SCALAR;
	var VEC2;
	var VEC3;
	var VEC4;
	var MAT2;
	var MAT3;
	var MAT4;
}

private enum abstract AttribName(String) to String {
	var POSITION;
	var NORMAL;
	var TANGENT;
	var TEXCOORD_0;
	var TEXCOORD_1;
	var JOINTS_0;
	var WEIGHTS_0;
}

// Convenient accessors for the "unique accessor lists" needed
// when converting to HMD
private enum abstract AccessorInd(Int) to Int {
	var POS = 0;
	var NOR;
	var TEX;
	var JOINTS;
	var WEIGHTS;
	var INDICES;
}

private typedef Asset = {
	version:String,
}

private typedef Buffer = {
	uri:String,
	byteLength:Int,
}

private typedef BufferView = {
	buffer:Int,
	byteLength:Int,
	byteOffset:Null<Int>,
	byteStride:Null<Int>,
}

private typedef Accessor = {
	bufferView:Int,
	componentType:ComponentType,
	byteOffset:Null<Int>,
	count:Int,
	type:AccessorType,
	min:Null<Array<Float>>,
	max:Null<Array<Float>>,
}

private typedef Primitive = {
	attributes:haxe.DynamicAccess<Int>,
	indices:Null<Int>,
	material:Null<Int>,
}

private typedef Mesh = {
	primitives:Array<Primitive>,
	name:String,
}

private typedef TextureRef = {
	index:Int,
	texCoord:Null<Int>,
}

private typedef PbrMatRough = {
	baseColorFactor:Null<Array<Float>>,
	baseColorTexture:Null<TextureRef>,
}

private typedef Material = {
	name:String,
	pbrMetallicRoughness:PbrMatRough,
}

private typedef Texture = {
	source:Int,
	sampler:Null<Int>,
}

private typedef Image = {
	uri:Null<String>,
	bufferView:Null<Int>,
	mimeType:Null<String>,
}

private typedef Sampler = {
	// TODO
}

private typedef Node = {
	children:Array<Int>,
	mesh:Null<Int>,
	skin:Null<Int>,
	translation:Null<Array<Float>>,
	rotation:Null<Array<Float>>,
	scale:Null<Array<Float>>,
	name:String,
}

private typedef Skin = {
	inverseBindMatrices:Int,
	joints:Array<Int>,
	skeleton:Null<Int>,
}

private typedef Scene = {
	nodes:Array<Int>,
	name:String,
}

private typedef AnimChannel = {
	sampler:Int,
	target: {node:Int, path: String},
}

private typedef AnimSampler = {
	input:Int,
	output:Int,
}

private typedef Animation = {
	channels:Array<AnimChannel>,
	samplers:Array<AnimSampler>,
	name:String,
}

private typedef GLTFData = {
	asset:Asset,
	accessors:Array<Accessor>,
	buffers:Array<Buffer>,
	bufferViews:Array<BufferView>,
	meshes:Array<Mesh>,
	materials:Array<Material>,
	nodes:Array<Node>,
	scenes:Array<Scene>,
	textures:Array<Texture>,
	images:Array<Image>,
	skins:Null<Array<Skin>>,
	animations:Null<Array<Animation>>,
}

class MeshData {
	public var primitives:Array<PrimitiveData> = [];
	public var name:String;
	public var uses:Int = 0;

	public function new() {}
}

class SkinData {
	public var invBindMatAcc: Int;
	public var skeleton: Null<Int>;
	public var joints: Array<Int>;
	public var jointNameMap: Map<String, Int>;
	public function new() {}
}

class MaterialData {
	public var color:Null<Int>;
	public var colorTex:String;

	public var name:String;

	public function new() {}
}

class NodeData {
	public var nodeInd: Int;
	public var name: String;
	public var parent: Null<NodeData> = null;
	public var children: Array<NodeData> = [];

	public var trans: Null<h3d.Vector> = null;
	public var rot: Null<Quat> = null;
	public var scale: Null<h3d.Vector> = null;

	public var outputID: Int = -1;

	public var mesh: Null<Int> = null;
	public var skin: Null<Int> = null;
	public var hasChildMesh: Bool = false;
	public var isJoint: Bool = false;
	public var isAnimated: Bool = false;
	public var animCurves: Array<AnimationCurve> = [];

	public function new() {}
}

typedef BuffAccess = {
	bufferInd:Int,
	offset:Int,
	stride:Int,
	compSize:Int,
	numComps:Int,
	count:Int,
	maxPos:Int,
}

typedef SampleInterp = {
	ind0:Int,
	ind1:Int,
	weight:Float,
}

class PrimitiveData {
	public var matInd:Null<Int>;

	public var pos:Int;
	public var norm:Null<Int>;
	public var texCoord:Null<Int>;
	public var joints:Null<Int>;
	public var weights:Null<Int>;
	public var indices:Null<Int>;
	public var accList:Array<Int>;

	public function new() {}
}

class AnimationCurve {
	public var transValues: Null<Array<Float>>;
	public var rotValues: Null<Array<Float>>;
	public var scaleValues: Null<Array<Float>>;
	public var targetName: String;
	public var targetNode: Int;

	public function new() {}
}

class AnimationData {
	public var length: Float;
	public var numFrames: Int;
	public var curves: Array<AnimationCurve>;
	public var name: String;

	public function new() {}
}

class GLTFParser {
	public var data:GLTFData;
	public var name:String;
	public var localDir:String;
	public var relDir:String;

	final SAMPLE_RATE = 60.0;

	public var bufferData:Array<haxe.io.Bytes> = [];
	public var accData:Array<BuffAccess> = [];
	public var meshes:Array<MeshData> = [];
	public var mats:Array<MaterialData> = [];
	public var rootNodes:Array<NodeData> = [];
	public var nodes:Array<NodeData> = []; // The data for the nodes in the same order as the source
	public var skins:Array<SkinData> = [];
	public var animations:Array<AnimationData> = [];

	public function new(name, localDir, relDir, file:haxe.io.Bytes) {
		this.name = name;
		this.localDir = localDir;
		this.relDir = relDir;

		this.data = Json.parse(file.getString(0, file.length));

		// Fixup node names before building the skin
		for (nodeInd in 0...data.nodes.length) {
			var node = data.nodes[nodeInd];
			if (node.name == null) {
				node.name = 'node_$nodeInd';
			}
		}

		loadBuffers();

		loadGeometry();

		loadSkins();

		loadMaterials();

		loadNodeTree();

		loadAnimations();

	}

	function loadBuffers() {
		// Read all files
		var buffers = data.buffers;
		for (buf in buffers) {
			// TODO: proper URI handling
			var buffBytes = sys.io.File.getBytes(localDir + buf.uri);
			if (buf.byteLength < buffBytes.length) {
				throw 'Buffer: ${buf.uri} is too small. Expected: ${buf.byteLength} bytes';
			}
			this.bufferData.push(buffBytes);
		}
		// Load the accessors
		for (acc in data.accessors) {
			accData.push(fillBuffAccess(acc));
		}
	}

	function checkAccessor(accInd:Int, ?expComp, ?expType) {
		var accessor = data.accessors[accInd];
		if (expComp != null)
			Debug.assert(accessor.componentType == expComp);
		if (expType != null)
			Debug.assert(accessor.type == expType);
	}

	function fillBuffAccess(accessor:Accessor):BuffAccess {
		var bufferView = data.bufferViews[accessor.bufferView];

		var compSize = componentSize(accessor.componentType);
		var numComps = numComponents(accessor.type);

		var elemSize = compSize*numComps;

		if (bufferView.byteOffset == null)
			bufferView.byteOffset = 0;

		if (accessor.byteOffset == null)
			accessor.byteOffset = 0;

		var offset = bufferView.byteOffset + accessor.byteOffset;


		var stride = (bufferView.byteStride != null) ? bufferView.byteStride : elemSize;

		var maxPos = bufferView.byteLength + bufferView.byteOffset;

		// Check the buffer view length logic
		Debug.assert( (accessor.byteOffset+stride*(accessor.count-1)+elemSize) <= bufferView.byteLength);

		return {
			bufferInd: bufferView.buffer,
			offset: offset,
			stride: stride,
			compSize: compSize,
			numComps: numComps,
			count: accessor.count,
			maxPos: maxPos,
		};
	}

	function loadGeometry() {
		for (mesh in data.meshes) {
			var meshData = new MeshData();
			meshData.name = mesh.name;
			for (prim in mesh.primitives) {
				var primData = new PrimitiveData();
				primData.accList = [-1, -1, -1, -1, -1, -1];
				primData.matInd = prim.material;
				var posAcc = prim.attributes.get(POSITION);
				var vertCount = data.accessors[posAcc].count;
				primData.pos = posAcc;
				checkAccessor(posAcc, FLOAT, VEC3);
				primData.accList[POS] = posAcc;
				var norAcc = prim.attributes.get(NORMAL);
				if (norAcc != null) {
					primData.norm = norAcc;
					checkAccessor(norAcc, FLOAT, VEC3);
					primData.accList[NOR] = norAcc;
					Debug.assert(data.accessors[norAcc].count >= vertCount);
				}
				var texAcc = prim.attributes.get(TEXCOORD_0);
				if (texAcc != null) {
					primData.texCoord = texAcc;
					checkAccessor(texAcc, FLOAT, VEC2);
					primData.accList[TEX] = texAcc;
					Debug.assert(data.accessors[texAcc].count >= vertCount);
				}
				var jointsAcc = prim.attributes.get(JOINTS_0);
				if (jointsAcc != null) {
					primData.joints = jointsAcc;
					checkAccessor(jointsAcc, UNSIGNED_SHORT, VEC4);
					primData.accList[JOINTS] = jointsAcc;
					Debug.assert(data.accessors[jointsAcc].count >= vertCount);
				}
				var weightsAcc = prim.attributes.get(WEIGHTS_0);
				if (weightsAcc != null) {
					primData.weights = weightsAcc;
					checkAccessor(weightsAcc, FLOAT, VEC4);
					primData.accList[WEIGHTS] = weightsAcc;
					Debug.assert(data.accessors[weightsAcc].count >= vertCount);
				}
				// Assert we have both or neither of joints and weights
				Debug.assert((weightsAcc == null) == (jointsAcc == null));

				primData.indices = prim.indices;
				if (primData.indices != null) {
					primData.accList[INDICES] = prim.indices;
					checkAccessor(prim.indices, null, SCALAR);
				}

				meshData.primitives.push(primData);
			}
			meshes.push(meshData);
		}
	}

	function loadSkins() {
		if (data.skins == null) return;
		for (skin in data.skins) {
			var skinData = new SkinData();
			skinData.invBindMatAcc = skin.inverseBindMatrices;
			checkAccessor(skinData.invBindMatAcc, FLOAT, MAT4);
			skinData.joints = skin.joints;

			// Save the names and check that they are unique
			skinData.jointNameMap = new Map();

			for (i in 0...skinData.joints.length) {
				var nodeId = skinData.joints[i];
				var nodeName = data.nodes[nodeId].name;
				Debug.assert(nodeName != null);
				if (skinData.jointNameMap[nodeName] != null) {
					throw 'Skin node name is used twice: $nodeName';
				}
				skinData.jointNameMap[nodeName] = i;
			}
			skins.push(skinData);
		}
	}

	function loadMaterials() {
		for (mat in data.materials) {
			var matData = new MaterialData();
			matData.name = mat.name;
			var metalRough = mat.pbrMetallicRoughness;
			if (metalRough.baseColorFactor != null) {
				var bc = metalRough.baseColorFactor;
				Debug.assert(bc.length >= 3);
				var colVec = new h3d.Vector(bc[0], bc[1], bc[2], bc.length >= 4 ? bc[3] : 1.0);
				matData.color = colVec.toColor();
			}
			if (metalRough.baseColorTexture != null) {
				var bc = metalRough.baseColorTexture;
				var texInd = bc.index;
				var texCoord = bc.texCoord != null ? bc.texCoord : 0;
				Debug.assert(texCoord == 0, "Only texcoord 0 supported for now");

				var tex = data.textures[texInd];
				var imageInd = tex.source;
				var image = data.images[imageInd];

				Debug.assert(image.uri != null);
				matData.colorTex = image.uri;
			}

			mats.push(matData);
		}
	}

	// Find the appropriate interval and weights from a time input curve
	function interpAnimSample(inAcc:BuffAccess, time:Float):SampleInterp {
		// Find the nearest input values
		var lastVal = getFloat(inAcc, 0,0);
		if (time <= lastVal) {
			return { ind0: 0, weight: 1.0, ind1:-1};
		}
		// Iterate until we reach the appropriate interval
		// TODO: something much less inefficient
		var nextVal = 0.0;
		var nextInd = 1;
		while(nextInd < inAcc.count) {
			nextVal = getFloat(inAcc, nextInd, 0);
			if (nextVal > time) {
				break;
			}
			Debug.assert(nextVal >= lastVal);
			lastVal = nextVal;
			nextInd++;
		}
		var lastInd = nextInd-1;

		if (nextInd == inAcc.count) {
			return { ind0: lastInd, weight: 1.0, ind1:-1};
		}

		Debug.assert(nextVal >= lastVal);
		Debug.assert(lastVal <= time);
		Debug.assert(time <= nextVal);
		if (nextVal == lastVal) {
			//Divide by zero guard
			return { ind0: lastInd, weight: 1.0, ind1:-1};
		}

		// calc weight
		var w = (nextVal-time)/(nextVal-lastVal);

		return { ind0: lastInd, weight: w, ind1:nextInd};

	}

	function loadAnimations() {
		if (data.animations == null) return;
		for (anim in data.animations) {
			// Figure out start and end times
			var startTime = Math.POSITIVE_INFINITY;
			var endTime = Math.NEGATIVE_INFINITY;
			for (chan in anim.channels) {
				var sampId = chan.sampler;
				var samp = anim.samplers[sampId];
				var inAcc = data.accessors[samp.input];
				if (inAcc.max != null) {
					var end = inAcc.max[0];
					endTime = Math.max(endTime, end);
				}
				if (inAcc.min != null) {
					var start = inAcc.min[0];
					startTime = Math.min(startTime, start);
				}
			}
			var length = endTime - startTime;
			var numFrames = Std.int(length * SAMPLE_RATE);

			function sampleCurve(sampId, numComps, isQuat) {
				var samp = anim.samplers[sampId];
				var inAcc = accData[samp.input];
				var outAcc = accData[samp.output];
				Debug.assert(outAcc.numComps == numComps);
				var values = new Array();
				values.resize(numFrames*outAcc.numComps);
				var vals0 = new Array();
				vals0.resize(numComps);
				var vals1 = new Array();
				vals1.resize(numComps);
				for (f in 0...numFrames) {
					var time = startTime+f*(1/SAMPLE_RATE);
					var samp = interpAnimSample(inAcc, time);
					if (samp.ind1 == -1) {
						for (i in 0...numComps) {
							values[f*numComps+i] = getFloat(outAcc, samp.ind0, i);
						}
						continue;
					}
					// Otherwise fill up the two values and interpolate
					for (i in 0...numComps) {
						vals0[i] = getFloat(outAcc, samp.ind0, i);
						vals1[i] = getFloat(outAcc, samp.ind1, i);
					}
					if (!isQuat) {
						// Simple lerp
						for (i in 0...numComps) {
							values[f*numComps+i] = vals0[i]*samp.weight + vals1[i]*(1.0-samp.weight);
						}
					} else {
						Debug.assert(numComps == 4);
						// Quaternion weirdness
						var q0 = new Quat(vals0[0], vals0[1], vals0[2], vals0[3]);
						var q1 = new Quat(vals1[0], vals1[1], vals1[2], vals1[3]);

						q0.lerp(q0, q1, samp.weight, true);
						values[f*numComps + 0] = q0.x;
						values[f*numComps + 1] = q0.y;
						values[f*numComps + 2] = q0.z;
						values[f*numComps + 3] = q0.w;
					}

				}
				return values;
			}

			var curves = [];
			var curvesPerNode : Map<Int, Array<AnimChannel>> = new Map();

			for (chan in anim.channels) {
				var nodeId = chan.target.node;
				var nodeList = curvesPerNode[nodeId];
				if (nodeList == null) {
					nodeList = [];
					curvesPerNode[nodeId] = nodeList;
				}
				nodeList.push(chan);
			}

			for (nodeId => channels in curvesPerNode) {
				var transPred = (chan) -> chan.target.path == "translation";
				var rotPred = (chan) -> chan.target.path == "rotation";
				var scalePred = (chan) -> chan.target.path == "scale";

				var numTrans = Lambda.count(channels, transPred);
				var numRot = Lambda.count(channels, rotPred);
				var numScale = Lambda.count(channels, scalePred);
				Debug.assert(numTrans <= 1);
				Debug.assert(numRot <= 1);
				Debug.assert(numScale <= 1);

				var curve = new AnimationCurve();
				curve.targetNode = nodeId;
				curve.targetName = data.nodes[nodeId].name;

				if (numTrans != 0) {
					var transChan = Lambda.filter(channels, transPred)[0];
					curve.transValues = sampleCurve(transChan.sampler, 3, false);
				}

				if (numRot != 0) {
					var rotChan = Lambda.filter(channels, rotPred)[0];
					curve.rotValues = sampleCurve(rotChan.sampler, 4, true);
				}

				if (numScale != 0) {
					var scaleChan = Lambda.filter(channels, scalePred)[0];
					curve.scaleValues = sampleCurve(scaleChan.sampler, 3, false);
				}

				curves.push(curve);
			}

			var animData = new AnimationData();
			animData.curves = curves;
			animData.length = length;
			animData.numFrames = numFrames;
			animData.name = anim.name;
			animations.push(animData);
		}

		// Mark all nodes as animated if it or any of its parents are animated
		for (node in nodes) {
			var n = node;
			while (n != null) {
				if (n.animCurves.length != 0) {
					node.isAnimated = true;
					break;
				}
				n = n.parent;
			}
		}
	}

	// Fill the data for this node, and recurse into its children
	function buildNode(curNode:NodeData, nodeInd:Int) {
		nodes[nodeInd] = curNode;

		var n = data.nodes[nodeInd];
		curNode.nodeInd = nodeInd;
		curNode.name = n.name;

		if (n.translation != null) {
			curNode.trans = new Vector(
				n.translation[0],
				n.translation[1],
				n.translation[2]);
		}
		if (n.scale != null) {
			curNode.scale = new Vector(
				n.scale[0],
				n.scale[1],
				n.scale[2]);
		}
		if (n.rotation != null) {
			curNode.rot = new Quat(
				n.rotation[0],
				n.rotation[1],
				n.rotation[2],
				n.rotation[3]);
		}
		if (n.mesh != null) {
			curNode.mesh = n.mesh;
			curNode.hasChildMesh = true;

			// Mark all ancestors
			var par = curNode.parent;
			while(par != null) {
				if (par.hasChildMesh) break;

				par.hasChildMesh = true;
				par = par.parent;
			}
		}
		if (n.skin != null) {
			curNode.skin = n.skin;
		}
		if (n.children != null) {
			for (cInd in n.children) {
				var c = data.nodes[cInd];
				var child = new NodeData();
				curNode.children.push(child);
				child.parent = curNode;
				buildNode(child, cInd);
			}
		}
	}

	function markJoints(node: NodeData) {
		node.isJoint = true;
		for (c in node.children) {
			markJoints(c);
		}
	}

	function loadNodeTree() {
		nodes.resize(data.nodes.length);

		for (scene in data.scenes) {
			for (nodeInd in scene.nodes) {
				var node = new NodeData();
				rootNodes.push(node);
				buildNode(node, nodeInd);
			}
		}

		// Mark all nodes listed in a skin as a joint
		for (skin in skins) {
			for (nodeInd in skin.joints) {
				nodes[nodeInd].isJoint = true;
			}
		}
		for (node in nodes) {
			// For now do not allow joints to have meshes
			Debug.assert(!node.isJoint || !node.hasChildMesh);
			if (node.isJoint) {
				for (c in node.children) {
					Debug.assert(c.isJoint);
				}
			}
		}
	}

	static function componentSize(compType:ComponentType):Int {
		return switch (compType) {
			case BYTE:
				1;
			case UNSIGNED_BYTE:
				1;
			case SHORT:
				2;
			case UNSIGNED_SHORT:
				2;
			case UNSIGNED_INT:
				4;
			case FLOAT:
				4;
			default:
				throw 'Unknown component $compType';
		}
	}

	static function numComponents(accType:AccessorType):Int {
		return switch (accType) {
			case SCALAR:
				1;
			case VEC2:
				2;
			case VEC3:
				3;
			case VEC4:
				4;
			case MAT2:
				4;
			case MAT3:
				9;
			case MAT4:
				16;
			default:
				throw 'Unknown accessor type $accType';
		}
	}

	function buildSkin(skin:SkinData, nodeName): hxd.fmt.hmd.Data.Skin {
		var ret = new hxd.fmt.hmd.Data.Skin();
		ret.name = (skin.skeleton != null ? nodes[skin.skeleton].name : nodeName) + "_skin";
		ret.props = null;
		ret.split = null;
		ret.joints = [];
		for (i in 0...skin.joints.length) {
			var jInd = skin.joints[i];
			var sj = new hxd.fmt.hmd.Data.SkinJoint();
			var node = nodes[jInd];
			sj.name = node.name;
			sj.props = null;
			sj.position = nodeToPos(node);
			sj.parent = skin.joints.indexOf(node.parent.nodeInd);
			sj.bind = i;

			// Get invBindMatrix
			var invBindMat = getMatrix(accData[skin.invBindMatAcc], i);
			sj.transpos = Position.fromMatrix(invBindMat);
			// Ensure this matrix converted to a 'Position' correctly
			var testMat = sj.transpos.toMatrix();
			//var testPos = Position.fromMatrix(testMat);
			Debug.assert(matNear(invBindMat, testMat));

			ret.joints.push(sj);
		}


		return ret;
	}

	public function toHMD():hxd.fmt.hmd.Data {
		var data = new haxe.io.BytesOutput();

		// Emit the geometry

		// Emit unique combinations of accessors
		// as a single buffer to save data
		var geoMap = new SeqIntMap();
		for (mesh in meshes) {
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
			dataPos.push(data.length);
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

			var posAcc = accData[accList[POS]];

			var genNormals = null;
			if (!hasNorm) {
				genNormals = generateNormals(posAcc);
			}

			var norAcc = accData[accList[NOR]];
			var texAcc = accData[accList[TEX]];
			var jointAcc = hasJoints ? accData[accList[JOINTS]] : null;
			var weightAcc = hasWeights ? accData[accList[WEIGHTS]] : null;

			for (i in 0...posAcc.count) {
				// Position data
				var x = getFloat(posAcc, i, 0);
				data.writeFloat(x);
				var y = getFloat(posAcc, i, 1);
				data.writeFloat(y);
				var z = getFloat(posAcc, i, 2);
				data.writeFloat(z);
				bb.addPos(x, y, z);

				// Normal data
				if (hasNorm) {
					data.writeFloat(getFloat(norAcc, i, 0));
					data.writeFloat(getFloat(norAcc, i, 1));
					data.writeFloat(getFloat(norAcc, i, 2));
				} else {
					var norm = genNormals[Std.int(i/3)];
					data.writeFloat(norm.x);
					data.writeFloat(norm.y);
					data.writeFloat(norm.z);
				}

				// Tex coord data
				if (hasTex) {
					data.writeFloat(getFloat(texAcc, i, 0));
					data.writeFloat(getFloat(texAcc, i, 1));
				} else {
					data.writeFloat(0.5);
					data.writeFloat(0.5);
				}

				// Note: Heaps currently only supports up to
				// 3 bones influencing a vertex at once
				// therefore drop the 4th index and weight
				// and renormalize the weights

				if (hasJoints) {
					for (jInd in 0...3) {
						var joint = getUShort(jointAcc, i, jInd);
						Debug.assert(joint >= 0);
						data.writeByte(joint);
					}
					data.writeByte(0);
				}
				if (hasWeights) {
					var weights =[];
					var sum = 0.0;
					for (wInd in 0...3) {
						var wVal = getFloat(weightAcc, i, wInd);
						Debug.assert(!Math.isNaN(wVal));
						weights.push(wVal);
						sum+=wVal;
					}

					data.writeFloat(weights[0]/sum);
					data.writeFloat(weights[1]/sum);
					data.writeFloat(weights[2]/sum);
					data.writeFloat(0);
				}
			}
		}

		// Find the unique combination of accessor lists in each
		// mesh. This will map on to the HMD geometry concept
		var meshAccLists:Array<Array<Int>> = [];
		for (mesh in meshes) {
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
		for (meshInd in 0...meshes.length) {
			var meshGeoList = [];
			meshToGeoMap.push(meshGeoList);

			var accList = meshAccLists[meshInd];
			for (accSet in accList) {
				var accessors = geoMap.getList(accSet);
				var posAcc = accData[accessors[0]];

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

				var mesh = meshes[meshInd];
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
						var indexAcc = accData[prim.indices];
						for (i in 0...indexAcc.count) {
							iList.push(getIndex(indexAcc, i));
						}
					} else {
						indexList[matInd] = [for (i in 0...geo.vertexCount) i];
					}
				}

				// Emit the indices
				geo.indexPosition = data.length;
				geo.indexCounts = Lambda.map(indexList, (x) -> x.length);
				for (inds in indexList) {
					for (i in inds) {
						data.writeUInt16(i);
					}
				}
			}
		}

		var materials = [];
		for (mat in mats) {
			var hMat = new hxd.fmt.hmd.Material();
			hMat.name = mat.name;

			if (mat.colorTex != null) {
				hMat.diffuseTexture = relDir + mat.colorTex;
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
		for (n in nodes) {
			// Mark the slot the node will be put into
			// while skipping over joints
			if (!n.isJoint) {
				n.outputID = nextOutID++;
			}
		}

		for (i in 0...nodes.length) {
			// Sanity check
			var node = nodes[i];
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
					model.skin = buildSkin(skins[node.skin], node.name);
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
						primModel.name = meshes[node.mesh].name;
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
		for (animData in animations) {
			var anim = new hxd.fmt.hmd.Data.Animation();
			anim.name = animData.name;
			anim.props = null;
			anim.frames = animData.numFrames;
			anim.sampling = SAMPLE_RATE;
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
			anim.dataPosition = data.length;
			for (f in 0...anim.frames) {
				for (curve in animData.curves) {
					if (curve.transValues != null) {
						data.writeFloat(curve.transValues[f*3+0]);
						data.writeFloat(curve.transValues[f*3+1]);
						data.writeFloat(curve.transValues[f*3+2]);
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
						data.writeFloat(quat.x);
						data.writeFloat(quat.y);
						data.writeFloat(quat.z);
					}
					if (curve.scaleValues != null) {
						data.writeFloat(curve.scaleValues[f*3+0]);
						data.writeFloat(curve.scaleValues[f*3+1]);
						data.writeFloat(curve.scaleValues[f*3+2]);
					}
				}
			}
			anims.push(anim);

		}

		var ret = new hxd.fmt.hmd.Data();
		#if hmd_version
		ret.version = Std.parseInt(#if macro haxe.macro.Context.definedValue("hmd_version") #else haxe.macro.Compiler.getDefine("hmd_version") #end);
		#else
		ret.version = Data.CURRENT_VERSION;
		#end
		ret.props = null;
		ret.materials = materials;
		ret.geometries = geos;
		ret.models = models;
		ret.animations = anims;
		ret.dataPosition = 0;

		ret.data = data.getBytes();

		return ret;
	}

	// retrieve the float value from an accessor for a specified
	// entry (eg: vertex) and component (eg: x)
	inline function getFloat(buffAcc:BuffAccess, entry:Int, comp:Int):Float {
		var buff = bufferData[buffAcc.bufferInd];
		Debug.assert(buffAcc.compSize == 4);
		var pos = buffAcc.offset + (entry * buffAcc.stride) + comp * 4;
		Debug.assert(pos < buffAcc.maxPos);
		return buff.getFloat(pos);
	}

	inline function getUShort(buffAcc:BuffAccess, entry:Int, comp:Int):Int {
		var buff = bufferData[buffAcc.bufferInd];
		Debug.assert(buffAcc.compSize == 2);
		var pos = buffAcc.offset + (entry * buffAcc.stride) + comp * 2;
		Debug.assert(pos < buffAcc.maxPos);
		return buff.getUInt16(pos);
	}

	function getMatrix(buffAcc:BuffAccess, entry:Int): h3d.Matrix {
		var floats = [];
		for (i in 0...16) {
			floats[i] = getFloat(buffAcc, entry, i);
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
	inline function getIndex(buffAcc:BuffAccess, entry:Int):Int {
		var buff = bufferData[buffAcc.bufferInd];
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

	function generateNormals(posAcc:BuffAccess) : Array<Vector> {
		Debug.assert(posAcc.count % 3 == 0);
		var numTris = Std.int(posAcc.count / 3);
		var ret = [];
		for (i in 0...numTris) {

			var ps = [];
			for (p in 0...3) {
				ps.push(new Vector(
					getFloat(posAcc, i*3+p,0),
					getFloat(posAcc, i*3+p,1),
					getFloat(posAcc, i*3+p,2)));
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
}
