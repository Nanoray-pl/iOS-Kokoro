//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class SwitchableListDataSourceTests: XCTestCase {
	func testPassthroughElements() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let testedDataSource = SwitchableListDataSource(initialDataSource: originalDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}

	func testPassthroughError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], error: Error.error)
		let testedDataSource = SwitchableListDataSource(initialDataSource: originalDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testPassthroughIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: true)
		let testedDataSource = SwitchableListDataSource(initialDataSource: originalDataSource)

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}

	func testSwitching() {
		let firstDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let secondDataSource = SnapshotListDataSource<Int>(elements: [], isFetching: true)
		let thirdDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5])
		let testedDataSource = SwitchableListDataSource(initialDataSource: firstDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		testedDataSource.switchDataSource(to: secondDataSource)

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		testedDataSource.switchDataSource(to: thirdDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 5)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 4, 5])
	}

	func testSwitchingAndReplacingCurrent() {
		let firstDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let secondDataSource = SnapshotListDataSource<Int>(elements: [], isFetching: true)
		let testedDataSource = SwitchableListDataSource(initialDataSource: firstDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		testedDataSource.switchDataSource(to: secondDataSource, replacingCurrent: true)

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 0)
		XCTAssertEqual(testedDataSource.elements, [])
	}
}
