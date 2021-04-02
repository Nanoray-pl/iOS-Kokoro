//
//  Created on 01/03/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroFetchable

class SkeletonListDataSourceTests: XCTestCase {
	private let skeletonBehavior = SkeletonListDataSourceBehavior(initialSkeletonCount: 3, additionalSkeletonCount: 1)

	func testNotFetchingWithNoElements() {
		let originalDataSource = SnapshotListDataSource<Int>(elements: [], isFetching: false)
		let testedDataSource = originalDataSource.withSkeletons(behavior: skeletonBehavior)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 0)
		XCTAssertEqual(testedDataSource.elements, [])
	}

	func testNotFetchingWithElements() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: false)
		let testedDataSource = originalDataSource.withSkeletons(behavior: skeletonBehavior)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3].map { .element($0) })
	}

	func testFetchingWithNoElements() {
		let originalDataSource = SnapshotListDataSource<Int>(elements: [], isFetching: true)
		let testedDataSource = originalDataSource.withSkeletons(behavior: skeletonBehavior)

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, Array(repeating: .skeleton, count: 3))
	}

	func testFetchingWithElements() {
		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], isFetching: true, isAfterInitialFetch: true)
		let testedDataSource = originalDataSource.withSkeletons(behavior: skeletonBehavior)

		XCTAssertEqual(testedDataSource.isFetching, true)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 4)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3].map { .element($0) } + [.skeleton])
	}

	func testError() {
		enum Error: Swift.Error {
			case error
		}

		let originalDataSource = SnapshotListDataSource(elements: [1, 2, 3], error: Error.error)
		let testedDataSource = originalDataSource.withSkeletons(behavior: skeletonBehavior)

		XCTAssertEqual(testedDataSource.isFetching, false)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3].map { .element($0) })

		switch testedDataSource.error {
		case .some(Error.error):
			break
		default:
			XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
		}
	}
}
