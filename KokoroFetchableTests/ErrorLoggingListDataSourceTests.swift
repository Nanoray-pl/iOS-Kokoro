//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils
import XCTest
@testable import KokoroFetchable

class ErrorLoggingListDataSourceTests: XCTestCase {
	func testMatchingByDescription() {
		enum Error: Swift.Error {
			case error1, error2
		}

		var loggedErrors = [Swift.Error]()
		let originalDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3]))
		let testedDataSource = originalDataSource.loggingErrors(errorMatchingStrategy: .byDescription) { loggedErrors.append($0) }

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertTrue(loggedErrors.isEmpty)

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error1))

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertFalse(loggedErrors.isEmpty)
		XCTAssertEqual(loggedErrors.count, 1)

		if let error = (testedDataSource.error as? LoggedError)?.wrappedError {
			switch error {
			case Error.error1:
				break
			default:
				XCTFail("Expected \(LoggedError(wrapping: Error.error1)), got \(String(describing: testedDataSource.error)) instead")
			}
		} else {
			XCTFail("Expected \(LoggedError(wrapping: Error.error1)), got \(String(describing: testedDataSource.error)) instead")
		}

		if let error = loggedErrors.last {
			switch error {
			case Error.error1:
				break
			default:
				XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
			}
		} else {
			XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
		}

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error2))

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertFalse(loggedErrors.isEmpty)
		XCTAssertEqual(loggedErrors.count, 2)

		if let error = (testedDataSource.error as? LoggedError)?.wrappedError {
			switch error {
			case Error.error2:
				break
			default:
				XCTFail("Expected \(LoggedError(wrapping: Error.error2)), got \(String(describing: testedDataSource.error)) instead")
			}
		} else {
			XCTFail("Expected \(LoggedError(wrapping: Error.error2)), got \(String(describing: testedDataSource.error)) instead")
		}

		if let error = loggedErrors.last {
			switch error {
			case Error.error2:
				break
			default:
				XCTFail("Expected \(Error.error2), got \(String(describing: loggedErrors.last)) instead")
			}
		} else {
			XCTFail("Expected \(Error.error2), got \(String(describing: loggedErrors.last)) instead")
		}
	}

	func testMatchingByPresenceOnly() {
		enum Error: Swift.Error {
			case error1, error2
		}

		var loggedErrors = [Swift.Error]()
		let originalDataSource = SwitchableListDataSource(initialDataSource: SnapshotListDataSource(elements: [1, 2, 3]))
		let testedDataSource = originalDataSource.loggingErrors(errorMatchingStrategy: .byPresenceOnly) { loggedErrors.append($0) }

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertNil(testedDataSource.error)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertTrue(loggedErrors.isEmpty)

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error1))

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertFalse(loggedErrors.isEmpty)
		XCTAssertEqual(loggedErrors.count, 1)

		if let error = (testedDataSource.error as? LoggedError)?.wrappedError {
			switch error {
			case Error.error1:
				break
			default:
				XCTFail("Expected \(LoggedError(wrapping: Error.error1)), got \(String(describing: testedDataSource.error)) instead")
			}
		} else {
			XCTFail("Expected \(LoggedError(wrapping: Error.error1)), got \(String(describing: testedDataSource.error)) instead")
		}

		if let error = loggedErrors.last {
			switch error {
			case Error.error1:
				break
			default:
				XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
			}
		} else {
			XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
		}

		originalDataSource.switchDataSource(to: SnapshotListDataSource(elements: [1, 2, 3], error: Error.error2))

		XCTAssertFalse(testedDataSource.isFetching)
		XCTAssertEqual(testedDataSource.count, 3)
		XCTAssertEqual(testedDataSource.elements, [1, 2, 3])
		XCTAssertFalse(loggedErrors.isEmpty)
		XCTAssertEqual(loggedErrors.count, 1)

		if let error = (testedDataSource.error as? LoggedError)?.wrappedError {
			switch error {
			case Error.error2:
				break
			default:
				XCTFail("Expected \(LoggedError(wrapping: Error.error2)), got \(String(describing: testedDataSource.error)) instead")
			}
		} else {
			XCTFail("Expected \(LoggedError(wrapping: Error.error2)), got \(String(describing: testedDataSource.error)) instead")
		}

		if let error = loggedErrors.last {
			switch error {
			case Error.error1:
				break
			default:
				XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
			}
		} else {
			XCTFail("Expected \(Error.error1), got \(String(describing: loggedErrors.last)) instead")
		}
	}
}
