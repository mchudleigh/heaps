package h3d.phys;

import h3d.TRSTrans;
import h3d.col.ConvexCollider;


class Body {

	public var shape: ConvexCollider;
	public var radius: Float;
	public var props: BodyProps;

	// The transform body space to world space
	public var trans: TRSTrans;

	public var velocity: Vector;
	public var angularVel: Vector;

	public var stationary: Bool;

	var constraints: Array<Constraint>;

	public function new() {
		constraints = [];
	}

	public function setTrans(t: TRSTrans) {
		trans = t;
	}

	public function getTrans(): TRSTrans {
		return trans;
	}
	public function setAngularVel(av: Vector) {
		angularVel.load(av);
		angularVel.w = 0;

//		angularVel.transform3x3(props.princRotMat);
	}
	public function setVelocity(vel: Vector) {
		velocity.load(vel);
		velocity.w = 0;
	}

	public function addConstraint(c: Constraint) {
		constraints.push(c);
	}
	public function removeConstraint(c: Constraint) {
		constraints.remove(c);
	}
	public function getConstraints(): Array<Constraint> {
		return constraints;
	}
}
