//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class SnapshotListDataSourceTests: XCTestCase {
	func testInitFromArray() {
		let elements = [1, 2, 3]
		let testedDataSource = SnapshotListDataSource(elements: elements)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}

	func testInitFromArrayAndError() {
		enum Error: Swift.Error {
			case error
		}

		let elements = [1, 2, 3]
		let error = Error.error
		let testedDataSource = SnapshotListDataSource(elements: elements, error: error)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testInitFromArrayAndIsFetching() {
		let elements = [1, 2, 3]
		let isFetching = true
		let testedDataSource = SnapshotListDataSource(elements: elements, isFetching: isFetching)

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}

	func testInitFromDataSource() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let testedDataSource = originalDataSource.snapshot()

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}

	func testInitFromDataSourceAndError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], error: Error.error)
		let testedDataSource = originalDataSource.snapshot()

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testInitFromDataSourceAndIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: true)
		let testedDataSource = originalDataSource.snapshot(configuration: .init(isFetching: .snapshot))

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
	}
}
