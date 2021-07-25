//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class MapListDataSourceTests: XCTestCase {
	func testMapping() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let testedDataSource = originalDataSource.map { String(repeating: "a", count: $0) }

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, ["a", "aa", "aaa"])
	}

	func testError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], error: Error.error)
		let testedDataSource = originalDataSource.map { String(repeating: "a", count: $0) }

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, ["a", "aa", "aaa"])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: true)
		let testedDataSource = originalDataSource.map { String(repeating: "a", count: $0) }

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, ["a", "aa", "aaa"])
	}
}
