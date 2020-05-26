package h3d.col;

import hxd.Debug;

class ConvexHull {
	static final VALIDATE = true;

	// Fundamental Data -------

	// Base list of points, most references will be via indices
	public var points: Array<Vector>;
	// faces is a flat array of 3 int tuples, indices into points
	// A valid face list must be closed and have all faces oriented facing
	// outward righthanded
	// Conveniently, this is also basically the index array for rendering triangles
	public var faces: Array<Int>;

	// Derived Data --------
	// Everything below can be derived from points and faces above

	// A flat 3 tuple for each face of the indices of the connected faces
	public var faceConnections: Array<Int> = new Array();

	public var facePlanes: Array<Plane> = new Array();

	// A list per point of connected points
	public var pointConnections: Array<Array<Int>> = new Array();
	// A parallel datastructure to pointConnections listing the direction
	// of that edge in a normalized vector from the point
	// this is effectively a cache for the GJK support function
	public var edgeDirs: Array<Array<Vector>> = new Array();

	// Mapping points back to faces
	public var pointFaces: Array<Array<Int>> = new Array();

	// Directional support function start points
	var suppPX: Int;
	var suppNX: Int;
	var suppPY: Int;
	var suppNY: Int;
	var suppPZ: Int;
	var suppNZ: Int;

	public function new(points, faces) {
		this.points = points;
		this.faces = faces;

		calcPointFaces();
		calcEdges();
		calcFaceConnections();
		calcPlanes();
		calcSuppPoints();

		if (VALIDATE)
			validate();
	}

	function calcPointFaces() {
		for (p in 0...points.length) {
			pointFaces[p] = [];
		}

		for (f in 0...Std.int(faces.length/3)) {
			for (pi in 0...3) {
				var pInd = facePoint(f, pi);
				pointFaces[pInd].push(f);
			}
		}
	}

	function calcEdges() {
		for (pInd in 0...points.length) {
			var connList = new Array();
			pointConnections[pInd] = connList;
			var dirList = new Array();
			edgeDirs[pInd] = dirList;
			var faceList = pointFaces[pInd];
			for (f in faceList) {
				var pOther = -1;
				for (pi in 0...3) {
					if (facePoint(f, pi) == pInd) {
						pOther = facePointMod(f, pi+1);
						break;
					}
				}
				Debug.assert(pOther != -1);

				connList.push(pOther);
				var edgeDir = points[pOther].sub(points[pInd]);
				edgeDir.normalize();
				dirList.push(edgeDir);
			}

		}
	}

	function calcFaceConnections() {
		for (f in 0...Std.int(faces.length/3)) {
			for (pi in 0...3) {
				var p0 = facePoint(f, pi);
				var p1 = facePointMod(f, pi+1);
				// Due to the constraints, there must be a face
				// with points p1, p0, pX or some rotation of this list
				// Go to p1 and find the face that satisfies this constraint
				var fInd = -1;
				for (testFace in pointFaces[p0]) {
					var testP = finishFace(testFace, p1, p0);
					if (testP != -1) {
						fInd = testFace;
						break;
					}
				}
				Debug.assert(fInd != -1);
				faceConnections.push(fInd);
			}
		}
	}
	function calcPlanes() {
		for (f in 0...Std.int(faces.length/3)) {
			var p0 = points[facePoint(f,0)];
			var p1 = points[facePoint(f,1)];
			var p2 = points[facePoint(f,2)];
			var plane = Plane.fromPoints(p0.toPoint(), p1.toPoint(), p2.toPoint());
			plane.normalize();
			facePlanes.push(plane);
		}
	}

	function support(dir: Vector): Vector {
		var p = -1;
		// Choose a starting point based on the 6 cardinal directions
		if (dir.x > 0.0 && dir.x > dir.y && dir.x > dir.z) {
			p = supportImp(dir, suppPX);
		} else if (dir.x < 0.0 && dir.x < dir.y && dir.x < dir.z) {
			p = supportImp(dir, suppNX);
		} else if (dir.y > 0 && dir.y > dir.z) {
			p = supportImp(dir, suppPY);
		} else if (dir.y < 0 && dir.y < dir.z) {
			p = supportImp(dir, suppNY);
		} else if(dir.z > 0) {
			p = supportImp(dir, suppPZ);
		} else {
			p = supportImp(dir, suppNZ);
		}

		return points[p];
	}

	function supportImp(dir: Vector, startPoint: Int): Int {
		var curP = startPoint;
		while(true) {
			var edges = pointConnections[curP];
			var eDirs = edgeDirs[curP];
			var bestDot = -1.0;
			var bestP = -1;
			for (ei in 0...edges.length) {
				var dot = dir.dot3(eDirs[ei]);
				if (dot > bestDot) {
					bestP = edges[ei];
					bestDot = dot;
				}
			}
			if (bestDot < 0.000001) {
				return curP;
			}
			curP = bestP;
		}
	}

	function calcSuppPoints() {
		suppPX = supportImp(new Vector( 1.0, 0.0, 0.0), 0);
		suppPY = supportImp(new Vector( 0.0, 1.0, 0.0), 0);
		suppPZ = supportImp(new Vector( 0.0, 0.0, 1.0), 0);

		suppNX = supportImp(new Vector(-1.0, 0.0, 0.0), 0);
		suppNY = supportImp(new Vector( 0.0,-1.0, 0.0), 0);
		suppNZ = supportImp(new Vector( 0.0, 0.0,-1.0), 0);
	}

	function validate() {
		// Ensure that each face is neighbour to 3 other faces
		var nCount = [];
		for (i in 0...Std.int(faces.length/3)) {
			nCount.push(0);
		}
		for (n in faceConnections) {
			nCount[n]++;
		}
		for (i in 0...Std.int(faces.length/3)) {
			Debug.assert(nCount[i] == 3);
		}

		// Check that each point connection has a return connection
		// and the direction is the opposite
		for (p in 0...points.length) {
			var conns = pointConnections[p];
			for (ci in 0...conns.length) {
				// Find the back connection
				var conn = conns[ci];
				var edgeDir = edgeDirs[p][ci];

				var found = false;
				for (bci in 0...pointConnections[conn].length) {
					var backConn = pointConnections[conn][bci];
					if (backConn == p) {
						Debug.assert(found == false);
						found = true;
						var backEdge = edgeDirs[conn][bci];
						var dirDot = backEdge.dot3(edgeDir);
						Debug.assert(Math.abs(dirDot+1.0) < 0.0001);
					}
				}
				Debug.assert(found);
			}
		}

		// Check that for every face the edge is present
		for (f in 0...Std.int(faces.length/3)) {
			for (pi in 0...3) {
				var p0 = facePoint(f, pi);
				var p1 = facePointMod(f, pi+1);

				// Find this edge
				var conns = pointConnections[p0];
				var found = false;
				for (tp in conns) {
					if (tp == p1) {
						Debug.assert(found == false);
						found = true;
					}
				}
				Debug.assert(found);
			}
		}

		// Check that every face can not "see" the third point
		// of each connected face (convexity check)
		for (f in 0...Std.int(faces.length/3)) {
			for (ei in 0...3) {
				var p0 = facePointMod(f, ei+0);
				var p1 = facePointMod(f, ei+1);
				var connFace = faceConnections[f*3+ei];
				var otherPoint = finishFace(connFace, p1, p0);
				Debug.assert(otherPoint != -1);
				var dist = facePlanes[f].distance(points[otherPoint].toPoint());
				Debug.assert(dist < 0.000001); // Slight threshold

			}
		}
	}

	// Utility to get the pInd point for face fInd
	inline function facePoint(fInd: Int, pInd: Int) {
		return faces[fInd*3+pInd];
	}
	// Like face point, but applies (mod 3) to pInd
	inline function facePointMod(fInd: Int, pInd: Int) {
		return faces[fInd*3+pInd%3];
	}
	// Returns the 3rd point if this face include p0 and p1 (in order)
	// Otherwise returns -1;
	function finishFace(f, p0, p1) {
		for (i in 0...3) {
			if (facePoint(f,i) == p0) {
				if (facePointMod(f, i+1) == p1) {
					return facePointMod(f, i+2);
				}
			}
		}
		return -1;
	}

	public function toPolygon(): h3d.prim.Polygon {
		var primPoints = [];
		for (v in points) {
			primPoints.push(v.toPoint());
		}
		var primIndices = new hxd.IndexBuffer();
		for (f in faces) {
			primIndices.push(f);
		}
		return new h3d.prim.Polygon(primPoints, primIndices);
	}

	public static function makeCubeHull(): ConvexHull {
		var cubePoints = [
			new Vector(-1.0,-1.0,-1.0),
			new Vector( 1.0,-1.0,-1.0),
			new Vector( 1.0, 1.0,-1.0),
			new Vector(-1.0, 1.0,-1.0),

			new Vector(-1.0,-1.0, 1.0),
			new Vector( 1.0,-1.0, 1.0),
			new Vector( 1.0, 1.0, 1.0),
			new Vector(-1.0, 1.0, 1.0)

		];

		var cubeFaces = [];
		function pushQuad(i0, i1, i2, i3) {
			cubeFaces.push(i0); cubeFaces.push(i1); cubeFaces.push(i2);
			cubeFaces.push(i0); cubeFaces.push(i2); cubeFaces.push(i3);
		}

		pushQuad(0,3,2,1); // -Z
		pushQuad(4,5,6,7); // +Z

		pushQuad(1,2,6,5); // +X
		pushQuad(0,4,7,3); // -X

		pushQuad(2,3,7,6); // +Y
		pushQuad(0,1,5,4); // -Y

		var cube = new ConvexHull(cubePoints, cubeFaces);
		return cube;
	}
	// Make a tetrahedron convex hull
	public static function makeTetraHull() {

		var rt3 = Math.sqrt(3);
		var tetraPoints = [
			new Vector(0, 0, 0),
			new Vector(rt3, -1, 0),
			new Vector(rt3,  1, 0),
			new Vector(2/3*rt3, 0, rt3)
		];

		var tetraFaces = [];
		function pushFace(i0, i1, i2) {
			tetraFaces.push(i0); tetraFaces.push(i1); tetraFaces.push(i2);
		}
		pushFace(0, 2, 1);
		pushFace(0, 1, 3);
		pushFace(1, 2, 3);
		pushFace(2, 0, 3);
		var tetra = new ConvexHull(tetraPoints, tetraFaces);
		return tetra;
	}

}
