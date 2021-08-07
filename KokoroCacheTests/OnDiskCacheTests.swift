//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils
import XCTest
@testable import KokoroCache

class OnDiskCacheTests: XCTestCase {
	private struct IntKey: OnDiskCacheable, ExpressibleByIntegerLiteral {
		let value: Int

		var cacheIdentifier: String {
			return "\(value)"
		}

		init(integerLiteral value: IntegerLiteralType) {
			self.value = value
		}
	}

	private func emptyData(withLength length: Int) -> Data {
		return Data([UInt8](repeating: 0, count: length))
	}

	func testOnDiskStore() {
		let fileManager = FileManager.default
		let cacheDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("/\(UUID().uuidString)", isDirectory: true)
		defer { try? fileManager.removeItem(at: cacheDirectoryUrl) }
		let cache = OnDiskCache<IntKey, OnDiskSerializableSerializer<Data>>(cacheDirectoryUrl: cacheDirectoryUrl, fileManager: fileManager, serializer: OnDiskSerializableSerializer())
		cache.options = .init(validity: .forever, serializeErrorBehavior: .noValue)

		let data = (0 ... 2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: .init(integerLiteral: $0)) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 0)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2) // 1 for the value, 1 for a list of entries

		cache.invalidateValue(for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1) // just the list of entries file

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 4)

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)
	}

	func testEntryCountLimit() {
		let fileManager = FileManager.default
		let cacheDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("/\(UUID().uuidString)", isDirectory: true)
		defer { try? fileManager.removeItem(at: cacheDirectoryUrl) }
		let cache = OnDiskCache<IntKey, OnDiskSerializableSerializer<Data>>(cacheDirectoryUrl: cacheDirectoryUrl, fileManager: fileManager, serializer: OnDiskSerializableSerializer())
		cache.options = .init(validity: .forever, entryCountLimit: 2, serializeErrorBehavior: .noValue)

		let data = (0 ... 2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: .init(integerLiteral: $0)) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 0)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.invalidateValue(for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)
	}

	func testTotalSizeLimit() {
		let fileManager = FileManager.default
		let cacheDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("/\(UUID().uuidString)", isDirectory: true)
		defer { try? fileManager.removeItem(at: cacheDirectoryUrl) }
		let cache = OnDiskCache<IntKey, OnDiskSerializableSerializer<Data>>(cacheDirectoryUrl: cacheDirectoryUrl, fileManager: fileManager, serializer: OnDiskSerializableSerializer())
		cache.options = .init(validity: .forever, totalSizeLimit: 3, serializeErrorBehavior: .noValue)

		let data = (0 ... 3).map { emptyData(withLength: $0) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: .init(integerLiteral: $0)) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 0)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 4)

		cache.store(data[3], for: 3)
		XCTAssertEqual(cacheValues(), expectedValues([3]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0, 3]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)
	}

	func testStorageDateInvalidation() {
		let fileManager = FileManager.default
		let cacheDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("/\(UUID().uuidString)", isDirectory: true)
		defer { try? fileManager.removeItem(at: cacheDirectoryUrl) }
		let mockScheduler = MockScheduler()
		let cache = OnDiskCache<IntKey, OnDiskSerializableSerializer<Data>>(cacheDirectoryUrl: cacheDirectoryUrl, fileManager: fileManager, serializer: OnDiskSerializableSerializer(), scheduler: mockScheduler)
		cache.options = .init(validity: .afterStorage(0.075), serializeErrorBehavior: .noValue)

		let data = (0 ... 2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: .init(integerLiteral: $0)) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 0)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 4)

		mockScheduler.advanceTime(by: 0.1)
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		mockScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		mockScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)
	}

	func testAccessDataInvalidation() {
		let fileManager = FileManager.default
		let cacheDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("/\(UUID().uuidString)", isDirectory: true)
		defer { try? fileManager.removeItem(at: cacheDirectoryUrl) }
		let mockScheduler = MockScheduler()
		let cache = OnDiskCache<IntKey, OnDiskSerializableSerializer<Data>>(cacheDirectoryUrl: cacheDirectoryUrl, fileManager: fileManager, serializer: OnDiskSerializableSerializer(), scheduler: mockScheduler)
		cache.options = .init(validity: .afterAccess(0.075), serializeErrorBehavior: .noValue)

		let data = (0 ... 2).map { emptyData(withLength: $0 * 8) }
		let cacheValues: () -> [Data?] = { data.indices.map { cache.value(for: .init(integerLiteral: $0)) } }
		let expectedValues: (_ indexes: [Int]) -> [Data?] = { indexes in data.indices.map { indexes.contains($0) ? data[$0] : nil } }

		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 0)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.store(data[2], for: 2)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1, 2]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 4)

		mockScheduler.advanceTime(by: 0.1)
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)

		cache.store(data[0], for: 0)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		mockScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([0]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 2)

		cache.store(data[1], for: 1)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		mockScheduler.advanceTime(by: 0.05)
		XCTAssertEqual(cacheValues(), expectedValues([0, 1]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 3)

		cache.invalidateAllValues()
		XCTAssertEqual(cacheValues(), expectedValues([]))
		XCTAssertEqual(try! fileManager.contentsOfDirectory(at: cacheDirectoryUrl, includingPropertiesForKeys: nil, options: []).count, 1)
	}
}
