//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class TryMapListDataSourceTests: XCTestCase {
	private enum TryMapError: Swift.Error {
		case error
	}

	func testMapWithSkipElementOnError() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5])
		let testedDataSource = originalDataSource.tryMap(errorBehavior: .skipElement) { value -> String in
			if value % 2 == 0 {
				return String(repeating: "a", count: value)
			} else {
				throw TryMapError.error
			}
		}

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 2)
		XCTAssertEqual(testedDataSource.elements, ["aa", "aaaa"])

		switch testedDataSource.error {
		case let .some(FetchableListDataSourceError.multipleErrors(errors)) where errors.count == 3:
			switch (errors[0], errors[1], errors[2]) {
			case (TryMapError.error, TryMapError.error, TryMapError.error):
				break
			default:
				XCTFail("Expected \(FetchableListDataSourceError.multipleErrors(Array(repeating: TryMapError.error, count: 3))), got \(String(describing: testedDataSource.error)) instead")
			}
		default:
			XCTFail("Expected \(FetchableListDataSourceError.multipleErrors(Array(repeating: TryMapError.error, count: 3))), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testMapWithEmptyListOnError() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3, 4, 5])
		let testedDataSource = originalDataSource.tryMap(errorBehavior: .emptyList) { value -> String in
			if value % 2 == 0 {
				return String(repeating: "a", count: value)
			} else {
				throw TryMapError.error
			}
		}

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 0)
		XCTAssertEqual(testedDataSource.elements, [])

		switch testedDataSource.error {
		case .some(TryMapError.error):
			break
		default:
			XCTFail("Expected \(TryMapError.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testUnderlyingError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1], error: Error.error)
		let testedDataSource = originalDataSource.tryMap { $0 }

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 1)
		XCTAssertEqual(testedDataSource.elements, [1])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testUnderlyingErrorAndMapError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1], error: Error.error)
		let testedDataSource = originalDataSource.tryMap { (_: Int) -> Int in throw TryMapError.error }

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 0)
		XCTAssertEqual(testedDataSource.elements, [])

		switch testedDataSource.error {
		case let .some(FetchableListDataSourceError.multipleErrors(errors)) where errors.count == 2:
			switch (errors[0], errors[1]) {
			case (Error.error, TryMapError.error):
				break
			default:
				XCTFail("Expected \(FetchableListDataSourceError.multipleErrors([Error.error, TryMapError.error])), got \(String(describing: testedDataSource.error)) instead")
			}
		default:
			XCTFail("Expected \(FetchableListDataSourceError.multipleErrors([Error.error, TryMapError.error])), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testIsFetching() {
		let originalDataSource = SnapshotListDataSource(elements: [1], isFetching: true)
		let testedDataSource = originalDataSource.tryMap { $0 }

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 1)
		XCTAssertEqual(testedDataSource.elements, [1])
	}
}
