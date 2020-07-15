package h3d.phys;

import h3d.col.ConvexCollider;
import h3d.col.HullCollision;
import h3d.TRSTrans;

import h3d.col.ColBuilder;
import h3d.col.ConvexHull;

// World is a containing class for a connected physics simulation
class World {

	var bodies: Array<Body>;
	var constraints: Array<Constraint>;
	var coll: HullCollision;

	public function new() {
		bodies = [];
		constraints = [];
		coll = new HullCollision();
	}

	public function addBody(body: Body) {
		bodies.push(body);
		// TODO: first half step velocity term (to bring it inline with Verlet)
	}


	public function simulate(dt: Float, calcCollision: Bool) {
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

		// Update positions
		for (body in bodies) {
			if (body.stationary) continue;

			// Linear displacement
			var disp = body.velocity.clone();
			disp.scale3(dt);
			body.trans.trans.incr(disp);

			// Angular displacement
			var axis = body.angularVel.clone();
			var theta = axis.length();
			axis.normalize();
			theta *= dt;
			var rotInc = new Quat();
			rotInc.initRotateAxis(axis.x, axis.y, axis.z, theta);

			// Actual rotation increment will be around the center of mass
			// in body space
			var bsCoM = body.props.com.toVector();
			bsCoM.transform(body.trans.toMatrix());
			var tempTrans = new TRSTrans(bsCoM, rotInc, 1.0);
			var negCoM = bsCoM.clone();
			negCoM.scale3(-1);
			var tempTrans2 = TRSTrans.fromTrans(negCoM);
			var incTrans = TRSTrans.compound(tempTrans, tempTrans2);

			body.trans = TRSTrans.compound(incTrans, body.trans);
		}

		if (calcCollision) {
			// Collide all pairs of bodies (O(N^2) for now but will be optimized)
			// Collisions can spontaneously update velocity (but not position)
			// but must attempt to conserve energy and momentum
			for (i in 0...bodies.length) {
				for (j in i...bodies.length) {
					collide(bodies[i], bodies[j]);
				}
			}
		}

		// Update constraints
		for (c in constraints) {
			c.update(dt);
		}

		// Calculate forces and torques from updated positions
		var forces = [];
		var torques = [];
		for (body in bodies) {
			if (body.stationary) {
				forces.push(null); torques.push(null);
				continue;
			}

			var forceAccum = new Vector();
			var torqueAccum = new Vector();
			for (c in body.getConstraints()) {
				var f = c.getForce(body);
				forceAccum.incr(f);
				var t = c.getTorque(body);
				torqueAccum.incr(t);
			}
			forces.push(forceAccum);
			torques.push(torqueAccum);
		}

		// Use forces and torques to update velocities
		for (i in 0...bodies.length) {

			var body = bodies[i];
			if (body.stationary) continue;

			var force = forces[i];
			var torque = torques[i];

			// Linear velocity (F = ma)
			var accel = force.clone();
			accel.scale3(dt/body.props.mass);
			body.velocity.incr(accel);

			// Convert torque to principal frame
			torque.transform3x3(body.props.princRotMat);

			// Angular velocity (This is based on Euler's rotation equations)
			var pMoI = body.props.principalMOI;
			var av = body.angularVel;
			var angAcc = new Vector();
			angAcc.x = (torque.x - (pMoI.z - pMoI.y)*av.y*av.z)/pMoI.x;
			angAcc.y = (torque.y - (pMoI.x - pMoI.z)*av.z*av.x)/pMoI.y;
			angAcc.z = (torque.z - (pMoI.y - pMoI.x)*av.x*av.y)/pMoI.z;
			angAcc.scale3(dt);
			// Convert angular delta back to the body frame
			angAcc.transform3x3(body.props.invPrincRotMat);
			body.angularVel.incr(angAcc);
		}
	}

	function collide(b0: Body, b1: Body) {

		var b0Trans = b0.getTrans();
		var b1Trans = b1.getTrans();
		// Easy radius test
		var rad = b0.radius*b0Trans.scale + b1.radius*b1Trans.scale;
		var diff = b0Trans.trans.sub(b1Trans.trans);
		if (diff.length() > rad) return; // No collision

		// Otherwise build up the collider
		var b0Col = ColBuilder.transform(b0.shape, b0Trans.toMatrix(), 42);
		var b1Col = ColBuilder.transform(b1.shape, b1Trans.toMatrix(), 42);

		var res = coll.testCollision(b0Col, b1Col, true);
		if (!res.collides) return;

		// Calculate collision reaction

		// Check for collision against stationary objects
		if (b0.stationary) {
			oneBodyCollision(b1, res, false);
			return;
		}
		if (b1.stationary) {
			oneBodyCollision(b0, res, true);
			return;
		}

		twoBodyCollision(b0, b1, res);
	}

	function oneBodyCollision(b: Body, colRes: ColRes, firstBody: Bool) {
		var bodyPt, worldPt;
		if (firstBody) {
			bodyPt = colRes.point.srcA;
			worldPt = colRes.point.srcB;
		} else {
			bodyPt = colRes.point.srcB;
			worldPt = colRes.point.srcA;
		}


	}

	function twoBodyCollision(b0: Body, b1: Body, colRes: ColRes) {

	}

	public static function hullToBody(hull: ConvexHull, bodyTrans: TRSTrans, density:Float = 1.0):Body {

		// TODO: collider ID
		var shape = ColBuilder.hull(hull, 42);

		var props = HullPhysics.calcProperties(hull, density);
		var ret = new Body();

		ret.radius = hull.radius;
		ret.shape = shape;
		ret.props = props;

		ret.setTrans(bodyTrans);

		ret.velocity = new Vector();
		ret.angularVel = new Vector();

		return ret;
	}
}
