package h3d.phys;

import h3d.TRSTrans;
import h3d.col.ConvexCollider;


class Body {

	public var shape: ConvexCollider;
	public var props: BodyProps;

	// This is the transform from shape space into body space
	// which is centered at the CoM and aligned with the principal axis
	public var principalTrans: TRSTrans;

	// The transform from (principal) body space to world space
	public var trans: TRSTrans;

	public var velocity: Vector;
	public var angularVel: Vector;

	public var stationary: Bool;

	public function new() {}
}
