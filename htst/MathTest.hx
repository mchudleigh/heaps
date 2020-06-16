package htst;

import h3d.Matrix;
import h3d.Vector;
import h3d.Quat;
import h3d.TRSTrans;
import utest.Assert;

class MathTest extends utest.Test {

	function testQuat() {

		var vec;
		// Test simple axis rotations
		var qZ90 = new Quat(0,0,1,1);
		qZ90.normalize();

		var rt2 = 1.0/Math.sqrt(2.0);
		Check.quat(0,0,rt2,rt2, qZ90);

		// Multiply by identity
		qZ90.multiply(qZ90, new Quat());
		Check.quat(0,0,rt2,rt2, qZ90);
		qZ90.multiply(new Quat(), qZ90);
		Check.quat(0,0,rt2,rt2, qZ90);

		vec = new Vector(1,0,0);
		vec.transform(qZ90.toMatrix());
		Check.vec3(0,1,0, vec);

		var qX90 = new Quat(1,0,0,1);
		qX90.normalize();
		Check.quat(rt2,0,0,rt2, qX90);

		vec = new Vector(0,1,0);
		vec.transform(qX90.toMatrix());
		Check.vec3(0,0,1, vec);

		// Compound quaternions
		var compQ = new Quat();
		compQ.multiply(qX90, qZ90);

		vec = new Vector(1,2,3);
		vec.transform(compQ.toMatrix());
		Check.vec3(-2,-3,1, vec);

		// Check inverting
		var q = new Quat(1,2,3,4);
		q.normalize();
		var conjQ = q.clone();
		conjQ.conjugate();
		var ident = new Quat();
		ident.multiply(q, conjQ);
		Check.quat(0,0,0,1, ident);

		ident.multiply(conjQ, q);
		Check.quat(0,0,0,1, ident);

		var invQZ90 = qZ90.clone();
		invQZ90.conjugate();

		// Reverse rotation via conjugate
		vec = new Vector(1,2,0);
		vec.transform(invQZ90.toMatrix());
		Check.vec3(2,-1,0, vec);
	}

	function testTRSTrans() {
		var vec;

		// Test T
		var trans = TRSTrans.fromTrans(new Vector(1,2,3));
		vec = new Vector(2,4,6);
		vec.transform(trans.toMatrix());
		Check.vec3(3,6,9, vec);

		var rot = TRSTrans.fromRot(new Quat(0,0,1,1)); // Will normalize
		vec = new Vector(2,1,0);
		vec.transform(rot.toMatrix());
		Check.vec3(-1,2,0, vec);

		var scale = TRSTrans.fromScale(42);
		vec = new Vector(2,1,0);
		vec.transform(scale.toMatrix());
		Check.vec3(84,42,0, vec);

		var rotScale = TRSTrans.compound(rot, scale);
		vec = new Vector(2,1,0);
		vec.transform(rotScale.toMatrix());
		Check.vec3(-42,84,0, vec);

		var transRot = TRSTrans.compound(trans, rot);
		vec = new Vector(2,1,0);
		vec.transform(transRot.toMatrix());
		Check.vec3(0,4,3, vec);

		var rotTrans = TRSTrans.compound(rot, trans);
		vec = new Vector(2,1,0);
		vec.transform(rotTrans.toMatrix());
		Check.vec3(-3,3,3, vec);

		var scaleRotTrans = TRSTrans.compound(scale, rotTrans);
		vec = new Vector(2,1,0);
		vec.transform(scaleRotTrans.toMatrix());
		Check.vec3(-126,126,126, vec);

		// Test inverse
		var invScaleRotTrans = scaleRotTrans.inverse();
		vec = new Vector(-126,126,126);
		vec.transform(invScaleRotTrans.toMatrix());
		Check.vec3(2,1,0, vec);

		var invRotTrans = rotTrans.inverse();
		vec = new Vector(-3,3,3);
		vec.transform(invRotTrans.toMatrix());
		Check.vec3(2,1,0, vec);

		// Test multiply by inverse
		var ident = TRSTrans.compound(invRotTrans, rotTrans);
		vec = new Vector(2,1,0);
		vec.transform(ident.toMatrix());
		Check.vec3(2,1,0, vec);
		// on both sides
		ident = TRSTrans.compound(rotTrans, invRotTrans);
		vec = new Vector(2,1,0);
		vec.transform(ident.toMatrix());
		Check.vec3(2,1,0, vec);

		var rotX = TRSTrans.fromRot(new Quat(1,0,0,1)); // Will normalize
		vec = new Vector(1,2,3);
		vec.transform(rotX.toMatrix());
		Check.vec3(1,-3,2, vec);

		// Compound rotations
		var rotXZ = TRSTrans.compound(rotX, rot);
		vec = new Vector(1,2,3);
		vec.transform(rotXZ.toMatrix());
		Check.vec3(-2,-3,1, vec);

	}
}
