//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class UniqueListDataSourceTests: XCTestCase {
	func testUniqueElements() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5])
		let uniqueDataSource = originalDataSource.uniquing()

		XCTAssertFalse(uniqueDataSource.isFetching)
		XCTAssertNil(uniqueDataSource.error)
		XCTAssertEqual(uniqueDataSource.count, 5)
		XCTAssertEqual(uniqueDataSource.elements, [1, 2, 3, 4, 5])
	}

	func testNonUniqueElements() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 1, 2, 2, 2])
		let uniqueDataSource = originalDataSource.uniquing()

		XCTAssertFalse(uniqueDataSource.isFetching)
		XCTAssertNil(uniqueDataSource.error)
		XCTAssertEqual(uniqueDataSource.count, 2)
		XCTAssertEqual(uniqueDataSource.elements, [1, 2])
	}

	func testError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource<Int>(elements: [], error: Error.error)
		let uniqueDataSource = originalDataSource.uniquing()

		XCTAssertFalse(uniqueDataSource.isFetching)
		XCTAssertEqual(uniqueDataSource.count, 0)
		XCTAssertEqual(uniqueDataSource.elements, [])

		switch uniqueDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: uniqueDataSource.error)) instead")
		}
	}

	func testIsFetching() {
		let originalDataSource = SnapshotListDataSource<Int>(elements: [], isFetching: true)
		let uniqueDataSource = originalDataSource.uniquing()

		XCTAssertTrue(uniqueDataSource.isFetching)
		XCTAssertNil(uniqueDataSource.error)
		XCTAssertEqual(uniqueDataSource.count, 0)
		XCTAssertEqual(uniqueDataSource.elements, [])
	}
}
