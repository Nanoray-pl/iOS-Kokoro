//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class MergeListDataSourceTests: XCTestCase {
	func testByDataSourceSortStrategy() {
		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3]))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3]))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByDataSourceSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])

		secondDataSource.switchDataSource(to: SnapshotListDataSource(elements: [42]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 4)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 42])

		firstDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 2)
		XCTAssertEqual(testedDataSource.elements, [0, 42])
	}

	func testByPageSortStrategy() {
		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3]))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3]))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByPageSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])

		secondDataSource.switchDataSource(to: SnapshotListDataSource(elements: [-1, -2, -3, -4]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 7)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3, -4])

		firstDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3, 4]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 8)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3, -4, 4])
	}

	func testSingleError() {
		enum Error: Swift.Error {
			case error
		}

		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3]))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByDataSourceSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testMultipleErrors() {
		enum Error: Swift.Error {
			case error
		}

		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3], error: Error.error))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByDataSourceSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])

		switch testedDataSource.error {
		case let .some(FetchableListDataSourceError.multipleErrors(errors)) where errors.count == 2:
			switch (errors[0], errors[1]) {
			case (Error.error, Error.error):
				break
			default:
				XCTFail("Expected \(FetchableListDataSourceError.multipleErrors(Array(repeating: Error.error, count: 2))), got \(String(describing: testedDataSource.error)) instead")
			}
		default:
			XCTFail("Expected \(FetchableListDataSourceError.multipleErrors(Array(repeating: Error.error, count: 2))), got \(String(describing: testedDataSource.error)) instead")
		}
	}

	func testSingleIsFetching() {
		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3], isFetching: true))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3]))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByDataSourceSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])
	}

	func testMultipleIsFetching() {
		let firstDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3], isFetching: true))
		let secondDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [-1, -2, -3], isFetching: true))
		let testedDataSource = MergeListDataSource(sortStrategySupplier: { MergeListDataSourceByDataSourceSortStrategy(dataSources: $0) }, dataSources: firstDataSource, secondDataSource)

		XCTAssertTrue(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 6)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, -1, -2, -3])
	}
}
