//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class EnumeratedListDataSourceTests: XCTestCase {
	func testMapping() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3])
		let testedDataSource = originalDataSource.enumeratedDataSource()

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements.map(\.offset), [0, 1, 2])
		XCTAssertEqual(testedDataSource.elements.map(\.element), [1, 2, 3])
	}

	func testError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], error: Error.error)
		let testedDataSource = originalDataSource.enumeratedDataSource()

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements.map(\.offset), [0, 1, 2])
		XCTAssertEqual(testedDataSource.elements.map(\.element), [1, 2, 3])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: true)
		let testedDataSource = originalDataSource.enumeratedDataSource()

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements.map(\.offset), [0, 1, 2])
		XCTAssertEqual(testedDataSource.elements.map(\.element), [1, 2, 3])
	}
}
