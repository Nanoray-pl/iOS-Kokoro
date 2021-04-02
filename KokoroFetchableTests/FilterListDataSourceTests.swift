//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class FilterListDataSourceTests: XCTestCase {
	func testFiltering() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5])
		let testedDataSource = originalDataSource.filter { $0 >= 3 }

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [3, 4, 5])
	}

	func testError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5], error: Error.error)
		let testedDataSource = originalDataSource.filter { $0 >= 3 }

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [3, 4, 5])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5], isFetching: true)
		let testedDataSource = originalDataSource.filter { $0 >= 3 }

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [3, 4, 5])
	}
}
