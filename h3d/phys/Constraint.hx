package h3d.phys;

import h3d.Vector;

interface Constraint {
	public function getForce(b: Body): Vector;
	public function getTorque(b: Body): Vector;

	public function update(dt: Float): Void;

	public function isDead(): Bool;
}
