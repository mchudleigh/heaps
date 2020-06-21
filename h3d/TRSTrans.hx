package h3d;

// A data holder to represent a TRS (translation, rotation and uniform scale)
// transformation. This encompasses a loose definition of a 7 dimensional
// Lie group and is well suited to rigid body dynamics (plus scale)
// Application is as listed for column vetors (ie: tranlation is outermost/last)
class TRSTrans {
	public var scale: Float;
	public var trans: Vector;
	public var rot: Quat;

	public function new(t, r, s) {
		this.trans = t;
		this.rot = r;
		r.normalize();
		this.scale = s;
	}


	public function toMatrix(): Matrix {
		var ret = new Matrix();
		rot.toMatrix(ret); // TODO: check handedness
		ret.scale(scale,scale,scale);
		ret.setPosition(trans);
		return ret;
	}

	public static function compound(outer: TRSTrans, inner: TRSTrans) {
		var outerRS = new Matrix();
		outer.rot.toMatrix(outerRS);
		outerRS.scale(outer.scale, outer.scale, outer.scale);

		var compT = inner.trans.clone();
		compT.transform3x3(outerRS);
		compT.incr(outer.trans);

		var compR = new Quat();
		compR.multiply(outer.rot, inner.rot);

		var compS = outer.scale * inner.scale;

		return new TRSTrans(compT, compR, compS);
	}

	public function inverse() {
		var rInv = rot.clone();
		rInv.conjugate();

		var sInv = 1.0/scale;

		var rsInv = new Matrix();
		rInv.toMatrix(rsInv);
		rsInv.scale(sInv, sInv, sInv);

		var tInv = trans.clone();
		tInv.scale3(-1.0);
		tInv.transform3x3(rsInv);

		return new TRSTrans(tInv, rInv, sInv);
	}

	public function clone() {
		return new TRSTrans(trans.clone(), rot.clone(), scale);
	}

	public static function fromTrans(trans: Vector): TRSTrans {
		return new TRSTrans(trans.clone(), new Quat(), 1.0);
	}
	public static function fromRot(rot: Quat): TRSTrans {
		return new TRSTrans(new Vector(), rot.clone(), 1.0);
	}
	public static function fromScale(scale: Float): TRSTrans {
		return new TRSTrans(new Vector(), new Quat(), scale);
	}
}
