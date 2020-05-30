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
			var ind = heap.popNext();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(0, heap.size());

		heap = new BinaryHeap(keys);
		var insInd = heap.insert(-10);
		var lowInd = heap.peekNext();
		Assert.equals(insInd, lowInd);

	}

	function testHeapInsert() {

		var keys = [for (i in 0...50) (50-i)*0.5];
		var heap = new BinaryHeap(keys);

		// Test inserting while popping
		heap = new BinaryHeap(keys);
		heap.validate();
		// Pop half
		for(i in 0...25) {
			var ind = heap.popNext();
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
			var ind = heap.popNext();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(10, heap.size());
		// Pop the 10 inserted
		for (i in 0...10) {
			var ind = heap.popNext();
			Assert.equals(insKeys[i], ind);
			heap.validate();
		}
		Assert.equals(0, heap.size());
		Assert.equals(-1, heap.popNext());
	}

	function testHeapRemove() {

		var keys = [for (i in 0...50) (50-i)*0.5];
		var heap = new BinaryHeap(keys);

		// Create a heap, remove half then test
		heap = new BinaryHeap(keys);
		heap.validate();
		// Remove the first half
		for(i in 0...25) {
			heap.remove(i);
			heap.validate();
		}
		Assert.equals(25, heap.size());
		// Pop the remainder
		for(i in 0...25) {
			var ind = heap.popNext();
			Assert.equals(49-i, ind);
			heap.validate();
		}
		Assert.equals(0, heap.size());
		Assert.equals(-1, heap.popNext());

	}

	function testHeapRemoveIterator() {

		var keys = [for (i in 0...50) (50-i)*0.5];
		var heap = new BinaryHeap(keys);

		// Create a heap, remove half then test
		heap = new BinaryHeap(keys);
		heap.validate();
		// Remove the first half
		for(i in 0...25) {
			heap.remove(i);
			heap.validate();
		}
		Assert.equals(25, heap.size());

		// Iterate over the second half
		var inds = [];
		for (ind in heap) {
			inds.push(ind);
		}
		Assert.equals(25, inds.length);
		inds.sort((a,b) -> a-b );
		for (i in 0...25) {
			Assert.equals(i+25, inds[i]);
		}

	}
}
