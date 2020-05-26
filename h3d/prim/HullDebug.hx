package h3d.prim;

import h3d.scene.Scene;
import h3d.mat.Material;
import h3d.col.ConvexHull;

class HullDebug {
	static var hullMat = null;

	static function initHullMat() {
		if (hullMat != null) return;

		var tex = h3d.mat.Texture.fromColor(0xFF8800, 0.9);
		hullMat = Material.create(tex);
		hullMat.blendMode = Add;
		hullMat.mainPass.depth(false, Always);
		hullMat.shadows = false;
	}

	public static function getHullMesh(hull: ConvexHull, scene: Scene) {
		initHullMat();
		var prim = hull.toPolygon();
		prim.unindex();
		prim.addNormals();
		prim.addUVs();

		var obj = new h3d.scene.Mesh(prim, hullMat);
		return obj;

	}
}
