package h3d.prim;

import h3d.scene.Scene;
import h3d.mat.Material;
import h3d.col.ConvexHull;
import h3d.col.ConvexCollider;
import h3d.col.HullBuilder;
import h3d.col.Point;

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

	public static function getHullPrimitive(hull: ConvexHull) {
		var prim = hull.toPolygon();
		prim.unindex();
		prim.addNormals();
		prim.addUVs();
		return prim;
	}

	public static function getHullMesh(hull: ConvexHull) {
		initHullMat();
		var prim = getHullPrimitive(hull);

		var obj = new h3d.scene.Mesh(prim, hullMat);
		return obj;

	}

	// Randomly sample a provided collider and create
	// ConvexHull of the provided points
	// This is a terrible idea for collision detection but useful
	// for visualization
	public static function colliderToMesh(col: ConvexCollider, numSamples = 1000, numFaces = 100) {
		var points = [];
		while (points.length < numSamples) {
			var x = 2*Math.random() -1; // Random on (-1,1)
			var y = 2*Math.random() -1; // Random on (-1,1)
			var z = 2*Math.random() -1; // Random on (-1,1)
			var mag = x*x + y*y + z*z;
			// Only sample inside the unit sphere to not bias the corners
			if (mag > 1) continue;
			mag = Math.sqrt(mag);
			var p = new Point();
			col.support(x/mag,y/mag,z/mag, p);
			points.push(p);
		}

		var hull = HullBuilder.buildHull(points, numFaces);
		return getHullMesh(hull);
	}

}
