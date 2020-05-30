package htst;

import utest.Assert;

import hds.BinaryHeap;

class HeapTest extends utest.Test {

	function testSimpleHeap() {
		// Create a simple array of floats to heapify

		var keys = [for (i in 0...50) (50-i)*0.5];
		var heap = new BinaryHeap(keys);
		Assert.equals(50, heap.size());

		heap.validate();

		for(i in 0...50) {
			var ind = heap.popLow();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(0, heap.size());

		heap = new BinaryHeap(keys);
		var insInd = heap.insert(-10);
		var lowInd = heap.getLow();
		Assert.equals(insInd, lowInd);

		// Test inserting while popping
		heap = new BinaryHeap(keys);
		heap.validate();
		// Pop half
		for(i in 0...25) {
			var ind = heap.popLow();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(25, heap.size());
		// Insert 10 more
		var insKeys = [];
		for (i in 0...10) {
			insKeys.push(heap.insert(80+i)); // Lower priority
		}
		Assert.equals(35, heap.size());
		// Pop the other half
		for(i in 25...50) {
			var ind = heap.popLow();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(10, heap.size());
		// Pop the 10 inserted
		for (i in 0...10) {
			var ind = heap.popLow();
			Assert.equals(insKeys[i], ind);
			heap.validate();
		}
		Assert.equals(0, heap.size());
		Assert.equals(-1, heap.popLow());
	}
}
