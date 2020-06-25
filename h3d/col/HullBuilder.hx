package h3d.col;

import hxd.Debug;

import h3d.col.ExpHull;


class HullBuilder implements ExpHullUser {

	static final THRESH = 0.0000001;
	var points: Array<Point>;

	var maxFaces: Int;

	// expanding hull (the core of the algorithm)
	var expHull: ExpHull;
	var orphans: Array<Int>;
	var unclaimed: Array<Int>;
	var init = true;
	// Points owned by the faces
	var ownedPoints: Array<Array<Int>>;

	// Temporary ownership needed due to how
	// ExpHull assigns indices
	var tempOwnedPoints: Array<Array<Int>>;

	public var finalHull: ConvexHull;

	function new(ps: Array<Point>, maxFaces) {
		this.points = ps;
		this.maxFaces = maxFaces;
		unclaimed = [];

		initialFaces();
		mainLoop();

		Debug.assert(unclaimed.length == 0);

		makeHull();
	}

	function initialFaces() {
		Debug.assert(points.length > 3);

		// Find 3 points to make the intial faces
		var px = -1; var nx = -1;
		var py = -1; var ny = -1;
		var pz = -1; var nz = -1;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;

		for (pi in 0...points.length) {
			var p = points[pi];
			if (p.x > maxX) { px = pi; maxX = p.x; }
			if (p.y > maxY) { py = pi; maxY = p.y; }
			if (p.z > maxZ) { pz = pi; maxZ = p.z; }

			if (p.x < minX) { nx = pi; minX = p.x; }
			if (p.y < minY) { ny = pi; minY = p.y; }
			if (p.z < minZ) { nz = pi; minZ = p.z; }
		}

		if (px==nx || py == ny || pz == nz) {
			Debug.assert(false, "Degenerate hull");
		}
		var sizeX = maxX-minX;
		var sizeY = maxY-minY;
		var sizeZ = maxZ-minZ;
		var p0, p1;
		if (sizeX > sizeY && sizeX > sizeZ) {
			p0 = px; p1 = nx;
		} else if (sizeY > sizeZ) {
			p0 = py; p1 = ny;
		} else {
			p0 = pz; p1 = nz;
		}
		// From the 2 initial points, find a third
		var diff = points[p0].sub(points[p1]);
		var max = Math.NEGATIVE_INFINITY;
		var p2 = -1;
		for (pi in 0...points.length) {
			var p = points[pi];
			var dist = diff.cross(p).lengthSq();
			if (dist > max && pi != p0 && pi != p1) {
				max = dist;
				p2 = pi;
			}
		}
		if (p2 == -1) {
			Debug.assert(false, "Degenerate hull");
		}

		orphans = [];
		for (pi in 0...points.length) {
			if (pi == p0 || pi == p1 || pi == p2) {
				continue;
			}
			orphans.push(pi);
		}

		ownedPoints = [];
		expHull = new ExpHull(points, [p0,p1,p2], this);
		init = false;
	}

	// Check if any the unclaimed points are inside the hull
	// drop them if they are
	function cleanUnclaimed() {
		if (unclaimed.length == 0)
			return;
		var newUnclaimed = [];
		for (p in unclaimed) {
			var outside = false;
			expHull.forEachFace(f -> {if (f.dist(p) > THRESH) outside = true;});
			if (outside)
				newUnclaimed.push(p);
		}
		unclaimed = newUnclaimed;
	}

	function mainLoop() {
		while(true) {
			var cont = expHull.iterate();
			if (!cont)
				return;

			if (expHull.faceHeap.size() >= maxFaces)
				return;

			cleanUnclaimed();
		}
	}

	function makeHull() {
		// Take the final list of faces from the main loop and make a hull
		var faceInds = [];
		for (fInd in expHull.faceHeap) {
			var f = expHull.faces[fInd];

			faceInds.push(f.verts[0]);
			faceInds.push(f.verts[1]);
			faceInds.push(f.verts[2]);
		}
		var vects = [];
		for (p in points) {
			vects.push(p.toVector());
		}
		finalHull = new ConvexHull(vects, faceInds);
	}

	public function onDeadFaces(deadFaces:Array<ExpFace>) {
		orphans = [];
		for(df in deadFaces) {
			var orphs = ownedPoints[df.ind];
			for (p in orphs) {
				orphans.push(p);
			}
		}
	}

	public function onNewFaces(newFaces: Array<ExpFace>):Array<NewFaceRes> {
		tempOwnedPoints = [];
		var bestDists = [];
		var bestPts = [];
		for (i in 0...newFaces.length) {
			tempOwnedPoints[i] = [];
			bestDists[i] = Math.NEGATIVE_INFINITY;
			bestPts[i] = -1;
		}

		// Find the best face for this point, returns true if successful
		function parentPoint(p): Bool {
			var bestDist = Math.NEGATIVE_INFINITY;
			var bestFace = -1;
			for (i in 0...newFaces.length) {
				var dist = newFaces[i].dist(p);
				if (dist > THRESH) {
					bestDist = dist;
					bestFace = i;
				}
			}
			if (bestFace != -1) {
				tempOwnedPoints[bestFace].push(p);
				if (bestDist > bestDists[bestFace]) {
					bestDists[bestFace] = bestDist;
					bestPts[bestFace] = p;
				}
				return true;
			}
			return false;
		}

		// Re parent all the orphans
		for (p in orphans) {
			if (!parentPoint(p)) {
				// If none of the new faces can "see" this point, it's
				// interior and silently dropped, unless...
				if (init) {
					// We do not abandon points during initial setup
					// these points must be in the plane of the initial
					// triangles. Mark them as unclaimed and eventually find
					// them a face
					unclaimed.push(p);
				} else {
					// Sanity check: Make sure abandoned points are inside all new faces
					// This is completely optional (and probably kills performance)
					if (ExpHull.VALIDATE) {
						for (f in newFaces) {
							Debug.assert(f.dist(p) < THRESH);
						}
					}
				}
			}
		}
		// Try to parent any unclaimed points
		if (!init && unclaimed.length > 0) {
			var newUnclaimed = [];
			for (p in unclaimed) {
				if (!parentPoint(p)) {
					newUnclaimed.push(p);
				}
			}
			unclaimed = newUnclaimed;
		}

		return [for (i in 0...newFaces.length)
			new NewFaceRes(-bestDists[i], bestPts[i], bestPts[i] == -1)];
	}

	public function afterAddFaces(newFaces: Array<ExpFace>) {
		// Once the faces have been assigned an index we can
		// set the proper ownership array
		for (i  in 0...newFaces.length) {
			ownedPoints[newFaces[i].ind] = tempOwnedPoints[i];
		}
	}

	public static function buildHull(points: Array<Point>, maxFaces = 100) : ConvexHull {

		var builder = new HullBuilder(points, maxFaces);

		return builder.finalHull;
	}

	public static function makeTestCube(): ConvexHull {
		var cubePoints = [
			new Point( 1, 1, 1),
			new Point(-1, 1, 1),
			new Point( 1,-1, 1),
			new Point(-1,-1, 1),

			new Point( 1, 1,-1),
			new Point(-1, 1,-1),
			new Point( 1,-1,-1),
			new Point(-1,-1,-1),
		];

		return buildHull(cubePoints);
	}
}
