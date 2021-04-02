//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class IgnoringUnchangedListDataSourceTests: XCTestCase {
	private class ClosureDataSourceObserver<Element>: FetchableListDataSourceObserver {
		private let closure: (_ dataSource: AnyFetchableListDataSource<Element>) -> Void

		init(closure: @escaping (_ dataSource: AnyFetchableListDataSource<Element>) -> Void) {
			self.closure = closure
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			closure(dataSource)
		}
	}

	func testIgnoringUnchanged() {
		let switchableDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3]))
		let testedDataSource = switchableDataSource.ignoringUnchanged()
		var changeCounter = 0
		let observer = ClosureDataSourceObserver<Int> { _ in changeCounter += 1 }
		testedDataSource.addObserver(observer)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertEqual(changeCounter, 0)

		switchableDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3], isFetching: true), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertEqual(changeCounter, 1)

		switchableDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3, 4]), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 4)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 4])
		XCTAssertEqual(changeCounter, 2)

		switchableDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3, 4]), replacingCurrent: true)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 4)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 4])
		XCTAssertEqual(changeCounter, 2)
	}
}
