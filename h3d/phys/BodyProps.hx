package h3d.phys;

import h3d.Matrix;

import h3d.col.Point;

// The physical proerties of a rigid body (excluding collision)
class BodyProps {

	public var mass: Float;

	// Center of Mass
	public var com: Point;
	// Moment of inertia matrix about CoM (in local coords)
	public var moi: Matrix;

	// The moment of inertia about the CoM on the principal axis
	public var principalMOI: Point;
	// The rotation for local coords to principal axis
	public var principalRot: Quat;

	public var princRotMat: Matrix;
	public var invPrincRotMat: Matrix;

	public function new() {}
}

