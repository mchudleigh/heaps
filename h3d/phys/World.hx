package h3d.phys;

import h3d.TRSTrans;

import h3d.col.ColBuilder;
import h3d.col.ConvexHull;

// World is a containing class for a connected physics simulation
class World {

	var bodies: Array<Body>;

	public function addBody(body: Body) {

	}


	public function simulate() {
		// This simulation is based on a Velocity Verlet integrator
		// where the velocity is technically a half time-step advanced.
		// This requires a fixed time-step to be accurate
		// The basic frame order is:
		// 1. Position update:
		//		P1 = P0 + V0*dt
		// 2. Calculate accellerations (forces) based on updated positions (including collision)
		// 		A = F(P1, V0)
		// 3. Velocity update:
		//		V1 = V0 + A*dt
	}

	public static function hullToBody(hull: ConvexHull, trans: TRSTrans, density:Float = 1.0):Body {

		// TODO: collider ID
		var shape = ColBuilder.hull(hull, 42);

		var props = HullPhysics.calcProperties(hull, density);
		var ret = new Body();

		ret.shape = shape;
		ret.props = props;
		ret.trans = trans;

		return ret;
	}
}
