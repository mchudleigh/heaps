package h3d.phys;

import h3d.TRSTrans;
import h3d.col.ConvexCollider;


class Body {

	public var shape: ConvexCollider;
	public var props: BodyProps;

	// The transform body space to world space
	public var trans: TRSTrans;

	public var velocity: Vector;
	public var angularVel: Vector;

	public var stationary: Bool;

	public function new() {}

	public function setTrans(t: TRSTrans) {
		trans = t;
	}

	public function getTrans(): TRSTrans {
		return trans;
	}
	public function setAngularVel(av: Vector) {
		angularVel.load(av);
		angularVel.w = 0;
	}
	public function setVelocity(vel: Vector) {
		velocity.load(vel);
		velocity.w = 0;
	}
}
