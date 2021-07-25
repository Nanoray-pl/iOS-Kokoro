//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroUtils

class SortedArrayTests: XCTestCase {
	func testUnsortedInit() {
		let tested: SortedArray<Int> = [1, 7, 3, 4, 2, 2, 1]
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 7)
		XCTAssertEqual(Array(tested), [1, 1, 2, 2, 3, 4, 7])
	}

	func testAdding() {
		var tested: SortedArray<Int> = []
		XCTAssertTrue(tested.isEmpty)
		XCTAssertEqual(tested.count, 0)
		XCTAssertEqual(Array(tested), [])

		tested.insert(1)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 1)
		XCTAssertEqual(Array(tested), [1])

		tested.insert(2)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 2)
		XCTAssertEqual(Array(tested), [1, 2])

		tested.insert(0)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 3)
		XCTAssertEqual(Array(tested), [0, 1, 2])

		tested.insert(1)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 4)
		XCTAssertEqual(Array(tested), [0, 1, 1, 2])
	}

	func testRemoving() {
		var tested: SortedArray<Int> = [0, 1, 2, 2, 3, 4]
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 6)
		XCTAssertEqual(Array(tested), [0, 1, 2, 2, 3, 4])

		tested.remove(0)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 5)
		XCTAssertEqual(Array(tested), [1, 2, 2, 3, 4])

		tested.remove(4)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 4)
		XCTAssertEqual(Array(tested), [1, 2, 2, 3])

		tested.remove(2)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 3)
		XCTAssertEqual(Array(tested), [1, 2, 3])

		tested.remove(4)
		XCTAssertFalse(tested.isEmpty)
		XCTAssertEqual(tested.count, 3)
		XCTAssertEqual(Array(tested), [1, 2, 3])
	}
}
