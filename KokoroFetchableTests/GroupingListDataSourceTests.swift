//
//  Created on 22/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class GroupingListDataSourceTests: XCTestCase {
	func testOddsAndEvens() {
		let originalDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource<Int>(elements: []))
		let testedDataSource = GroupingListDataSource(wrapping: originalDataSource, controllingGroups: .all) { $0 % 2 }

		XCTAssertTrue(testedDataSource.dataSources.isEmpty)

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.dataSources.isEmpty)
		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.dataSources.isEmpty)
		XCTAssertEqual(testedDataSource.dataSources.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0])
		XCTAssertEqual(testedDataSource.dataSources[1].group, 1)
		XCTAssertFalse(testedDataSource.dataSources[1].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[1].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.elements, [1])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 2]), replacingCurrent: true)

		XCTAssertFalse(testedDataSource.dataSources.isEmpty)
		XCTAssertEqual(testedDataSource.dataSources.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 2])
		XCTAssertEqual(testedDataSource.dataSources[1].group, 1)
		XCTAssertFalse(testedDataSource.dataSources[1].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[1].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.elements, [1])
	}

	func testSortedSplitDataWithInherentGroup() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource<Int>(elements: []))
		let testedDataSource = GroupingListDataSource(wrapping: originalDataSource, inherentGroup: 0, controllingGroups: .last) { $0 / 10 }

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 0)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [], isFetching: true), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertTrue(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 0)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9]), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9], isFetching: true), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertTrue(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9], error: Error.error), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])

		switch testedDataSource.dataSources[0].dataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.dataSources[0].dataSource.error)) instead")
		}

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9], isFetching: true), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertTrue(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9, 11, 19, 23]), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 3)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])
		XCTAssertEqual(testedDataSource.dataSources[1].group, 1)
		XCTAssertFalse(testedDataSource.dataSources[1].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[1].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.elements, [11, 19])
		XCTAssertEqual(testedDataSource.dataSources[2].group, 2)
		XCTAssertFalse(testedDataSource.dataSources[2].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[2].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.elements, [23])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9, 11, 19, 23], isFetching: true), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 3)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])
		XCTAssertEqual(testedDataSource.dataSources[1].group, 1)
		XCTAssertFalse(testedDataSource.dataSources[1].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[1].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.elements, [11, 19])
		XCTAssertEqual(testedDataSource.dataSources[2].group, 2)
		XCTAssertTrue(testedDataSource.dataSources[2].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[2].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.elements, [23])

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [0, 1, 5, 9, 11, 19, 23], error: Error.error), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.dataSources.count, 3)
		XCTAssertEqual(testedDataSource.dataSources[0].group, 0)
		XCTAssertFalse(testedDataSource.dataSources[0].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[0].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.count, 4)
		XCTAssertEqual(testedDataSource.dataSources[0].dataSource.elements, [0, 1, 5, 9])
		XCTAssertEqual(testedDataSource.dataSources[1].group, 1)
		XCTAssertFalse(testedDataSource.dataSources[1].dataSource.isFetching)
		XCTAssertNil(testedDataSource.dataSources[1].dataSource.error)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.count, 2)
		XCTAssertEqual(testedDataSource.dataSources[1].dataSource.elements, [11, 19])
		XCTAssertEqual(testedDataSource.dataSources[2].group, 2)
		XCTAssertFalse(testedDataSource.dataSources[2].dataSource.isFetching)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.count, 1)
		XCTAssertEqual(testedDataSource.dataSources[2].dataSource.elements, [23])

		switch testedDataSource.dataSources[2].dataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.dataSources[2].dataSource.error)) instead")
		}
	}
}
