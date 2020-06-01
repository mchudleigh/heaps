package hds;

import hxd.Debug;
// An implementation of a simple binary heap
// That does not store elements, but instead
// relies on provided "key" values to maintain the heap
// property. This is a "min-heap" AKA: lowest key is highest priority
// The indended use case is the user maintains a parallel
// array of meaningful data with the same indices as "keys"
// New indices are returned on insert, and the index of the appropriate
// element is returned when "popped"
// The sytsem will maintain a list of freed indices and reuse
// old slots in a LIFO order

class HeapIt {

	var h: BinaryHeap;
	var pos: Int;

	public inline function new(h) {
		this.h = h;
		this.pos = 0;
		skipDead();
	}

	function skipDead() {
		while(h.dead[h.heap[pos]] && pos < h.heap.length)
			++pos;
	}

	public function hasNext():Bool {
		return pos < h.heap.length;
	}
	public function next():Int {
		var ret = h.heap[pos++];
		skipDead();
		return ret;
	}
}

class BinaryHeap {

	static final DEAD_THRESH = 0.5;

	@:allow(hds.HeapIt)
	var heap: Array<Int>;

	var keys: Array<Float>;
	// "Removing" entries flags them as dead, but are not removed until
	// they pop of the top. This is all tranparent to the user
	@:allow(hds.HeapIt)
	var dead: Array<Bool>;
	var numDead: Int;
	var nextFree: Float;

	public function new(?keyVals: Array<Float>) {
		if (keyVals != null) {
			keys = [for (k in keyVals) k];
			heap = [for (i in 0...keys.length) i];
			dead = [for (i in 0...keys.length) false];
			heapify();
		} else {
			heap = [];
			keys = [];
			dead = [];
		}
		nextFree = -1;
		numDead = 0;
	}

	inline function has(i):Bool {
		return i < heap.length;
	}
	inline function key(i):Float {
		return keys[heap[i]];
	}
	inline function swap(i0:Int, i1: Int) {
		var t = heap[i0];
		heap[i0] = heap[i1];
		heap[i1] = t;
	}

	// Heapify the whole heap
	function heapify() {
		var i = Math.floor(heap.length/2);
		while(i >= 0) {
			downHeap(i--);
		}
	}
	// Insert a new value and maintain the heap property
	// returns the index associated with this key
	public function insert(key: Float):Int {
		popDead();
		var ind = if (nextFree != -1) {
			// Pop one entry off the free list
			var newFree = nextFree;
			nextFree = keys[Std.int(nextFree)];
			Std.int(newFree);
		} else {
			// Otherwise push
			keys.length;
		}
		keys[ind] = key;
		dead[ind] = false;
		var pos = heap.length;
		heap.push(ind);
		upHeap(pos);
		return ind;
	}

	public function remove(index: Int) {
		Debug.assert(!dead[index]); // Do not allow re-removal
		dead[index] = true;
		++numDead;
		if (numDead/heap.length > DEAD_THRESH) {
			// This array has too many dead entries
			// perform a "GC"
			cleanupDead();
		}
	}

	function popDead() {
		while(heap.length != 0 && dead[heap[0]]) {
			pop();
			numDead--;
		}
	}
	function cleanupDead() {
		Debug.assert(keys.length == dead.length); // Gratuitous sanity check

		// Force all dead entries to the top of the heap
		// then pop them all
		for (i in 0...dead.length) {
			if (dead[i]) {
				keys[i] = Math.NEGATIVE_INFINITY; // Max priority!!
			}
		}
		heapify();
		popDead();
	}

	function pop():Int {
		if (heap.length == 0) return -1;
		var low = heap[0];
		var last = heap.pop();
		if (heap.length != 0) {
			heap[0] = last;
			downHeap(0);
		}

		dead[low] = false;

		keys[low] = nextFree;
		nextFree = low;
		return low;
	}
	public function peekNext():Int {
		popDead();
		if (heap.length == 0) return -1;
		return heap[0];
	}
	public function popNext():Int{
		popDead();
		return pop();
	}

	public function size():Int {
		return heap.length - numDead;
	}

	function upHeap(pos:Int) {
		var i = pos;
		for (_ in 0...heap.length) { // Max iterations just in case
			if (i == 0) return; // Top of the heap

			var par = Math.floor((i-1)/2);
			if (key(i) < key(par)) {
				swap(i, par);
				i = par;
			} else {
				return;
			}
		}
		throw "Heap logic error!";
	}

	function downHeap(pos: Int) {
		var i = pos;
		for (_ in 0...heap.length) { // Max iterations just in case
			var l = 2*i+1;
			var r = 2*i+2;
			var low = i;
			if (has(l) && key(l) < key(low))
				low = l;
			if (has(r) && key(r) < key(low))
				low = r;

			if (low != i) {
				swap(low, i);
				// Bubble down
				i = low;
			} else {
				return;
			}
		}
		throw "Heap logic error!";
	}

	public function validate() {
		for (i in 0...Math.floor(heap.length/2)) {
			var l = 2*i+1;
			var r = 2*i+2;
			if (has(l))
				Debug.assert(key(i) <= key(l));
			if (has(r))
				Debug.assert(key(i) <= key(r));
		}

		// Validate the free list
		var freeSlots = keys.length - heap.length;
		var curSlot = nextFree;
		for (i in 0...freeSlots) {
			Debug.assert(curSlot != -1);
			curSlot = keys[Std.int(curSlot)];
		}
		Debug.assert(curSlot == -1);

		// Check the dead count
		var d = 0;
		for (i in 0...heap.length) {
			if (dead[heap[i]])
				d++;
		}
		Debug.assert(this.numDead == d);
	}

	public inline function iterator() {
		return new HeapIt(this);
	}
}
