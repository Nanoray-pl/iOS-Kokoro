//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils
import XCTest
@testable import KokoroCache

class InMemoryCacheTests: XCTestCase {
	private func emptyData(withLength length: Int) -> Data {
		return Data([UInt8](repeating: 0, count: length))
	}

	func testEntryCountLimit() {
		let cache = InMemoryCache<Int, Data> { $0.count }
		cache.options = .init(validity: .forever, entryCountLimit: 2)

		let data = (0...2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: $0) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([1, 2]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 2]))

		cache.invalidateValue(for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([2]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([1, 2]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
	}

	func testTotalSizeLimit() {
		let cache = InMemoryCache<Int, Data> { $0.count }
		cache.options = .init(validity: .forever, totalSizeLimit: 3)

		let data = (0...3).map { emptyData(withLength: $0) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: $0) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))

		cache.store(data[3], for: 3)
		XCTAssertEqual(cacheValues(), expectedValues([3]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 3]))

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
	}

	func testStorageDateInvalidation() {
		let synchronousScheduler = SynchronousScheduler()
		let cache = InMemoryCache<Int, Data>(scheduler: synchronousScheduler) { $0.count }
		cache.options = .init(validity: .afterStorage(0.04))

		let data = (0...2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: $0) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))

		synchronousScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		synchronousScheduler.advanceTime(by: 0.025)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		synchronousScheduler.advanceTime(by: 0.025)
		XCTAssertEqual(cacheValues(), expectedValues([1]))

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
	}

	func testAccessDataInvalidation() {
		let synchronousScheduler = SynchronousScheduler()
		let cache = InMemoryCache<Int, Data>(scheduler: synchronousScheduler) { $0.count }
		cache.options = .init(validity: .afterAccess(0.04))

		let data = (0...2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: $0) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))

		synchronousScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([]))

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		synchronousScheduler.advanceTime(by: 0.025)
		XCTAssertEqual(cacheValues(), expectedValues([0]))

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		synchronousScheduler.advanceTime(by: 0.025)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
	}
}
