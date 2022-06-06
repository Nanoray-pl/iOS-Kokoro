//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation) && canImport(CryptoKit) && canImport(ObjectiveC)
import Foundation
import KokoroAsync
import KokoroUtils
import ObjectiveC

public protocol OnDiskCacheable: Hashable {
	var cacheIdentifier: String { get }
}

public protocol OnDiskSerializable {
	func serialize() -> Data
	static func deserialize(_ data: Data) throws -> Self
}

public protocol OnDiskSerializer {
	associatedtype Value

	func serialize(_ value: Value) -> Data
	func deserialize(_ data: Data) throws -> Value
}

public class ClosureOnDiskSerializer<Value>: OnDiskSerializer {
	private let serializeClosure: (Value) -> Data
	private let deserializeClosure: (Data) throws -> Value

	public init(serializeClosure: @escaping (Value) -> Data, deserializeClosure: @escaping (Data) throws -> Value) {
		self.serializeClosure = serializeClosure
		self.deserializeClosure = deserializeClosure
	}

	public func serialize(_ value: Value) -> Data {
		return serializeClosure(value)
	}

	public func deserialize(_ data: Data) throws -> Value {
		return try deserializeClosure(data)
	}
}

extension Data: OnDiskSerializable {
	public func serialize() -> Data {
		return self
	}

	public static func deserialize(_ data: Data) throws -> Data {
		return data
	}
}

public class OnDiskSerializableSerializer<Value: OnDiskSerializable>: OnDiskSerializer {
	public func serialize(_ value: Value) -> Data {
		return value.serialize()
	}

	public func deserialize(_ data: Data) throws -> Value {
		return try Value.deserialize(data)
	}
}

public class OnDiskCache<Key, Serializer>: Cache where Key: OnDiskCacheable, Serializer: OnDiskSerializer {
	public typealias Value = Serializer.Value

	public struct Options {
		public enum Validity {
			public enum InvalidationOrder {
				case byStorageDate, byAccessDate
			}

			case forever
			case afterStorage(_ time: TimeInterval)
			case afterAccess(_ time: TimeInterval)

			public var invalidationOrder: InvalidationOrder {
				switch self {
				case .forever, .afterStorage:
					return .byStorageDate
				case .afterAccess:
					return .byAccessDate
				}
			}
		}

		public enum SerializeErrorBehavior {
			case noValue
			case defaultValue(_ defaultValue: Value)
			case handler(_ handler: (_ key: Key) -> Value)
		}

		public var validity: Validity
		public var entryCountLimit: Int?
		public var totalSizeLimit: Int?
		public var serializeErrorBehavior: SerializeErrorBehavior

		public init(validity: Validity = .forever, entryCountLimit: Int? = nil, totalSizeLimit: Int? = nil, serializeErrorBehavior: SerializeErrorBehavior) {
			self.validity = validity
			self.entryCountLimit = entryCountLimit
			self.totalSizeLimit = totalSizeLimit
			self.serializeErrorBehavior = serializeErrorBehavior
		}
	}

	private class Entry: Codable {
		let cacheIdentifier: String
		let valueSize: Int
		var invalidationDate: Date?

		init(cacheIdentifier: String, valueSize: Int, validUntil: Date?) {
			self.cacheIdentifier = cacheIdentifier
			self.valueSize = valueSize
			invalidationDate = validUntil
		}
	}

	public var options = Options(
		validity: .afterAccess(60 * 60 * 24), // 1 day
		serializeErrorBehavior: .noValue
	)

	private let cacheDirectoryUrl: URL
	private let fileManager: FileManager
	private let serializer: Serializer
	private let scheduler: Scheduler
	private let lock: Lock = DefaultLock()

	private lazy var cacheEntriesFileUrl = cacheDirectoryUrl.appendingPathComponent("/cache.json")

	private var entries = [String: Entry]()
	private var entriesSortedByInvalidationDate = SortedArray<Entry>(comparator: {
		switch ($0.invalidationDate, $1.invalidationDate) {
		case let (.some(lhs), .some(rhs)):
			return lhs < rhs
		case (.some, _):
			return true
		case (_, _):
			return false
		}
	})
	private var scheduledInvalidation: (cacheIdentifier: String, workItem: DispatchWorkItem)?
	private var currentSize = 0

	public init(cacheDirectoryUrl: URL, fileManager: FileManager = .default, serializer: Serializer, scheduler: Scheduler = DispatchQueue.global(qos: .background)) {
		self.cacheDirectoryUrl = cacheDirectoryUrl.standardizedFileURL
		self.fileManager = fileManager
		self.serializer = serializer
		self.scheduler = scheduler

		var isDirectory: ObjCBool = false
		let directoryExists = fileManager.fileExists(atPath: cacheDirectoryUrl.path, isDirectory: &isDirectory)

		switch (directoryExists: directoryExists, isDirectory: isDirectory.boolValue) {
		case (directoryExists: true, isDirectory: false):
			try! fileManager.removeItem(at: cacheDirectoryUrl)
			try! fileManager.createDirectory(at: cacheDirectoryUrl, withIntermediateDirectories: true)
		case (directoryExists: false, _):
			try! fileManager.createDirectory(at: cacheDirectoryUrl, withIntermediateDirectories: true)
		case (directoryExists: true, isDirectory: true):
			restoreEntries()
		}
	}

	private func restoreEntries() {
		lock.acquireAndRun {
			entries = [:]
			entriesSortedByInvalidationDate.removeAll()
			currentSize = 0

			if let data = try? Data(contentsOf: cacheEntriesFileUrl) {
				let decoder = JSONDecoder()
				entries = (try? decoder.decode([String: Entry].self, from: data)) ?? [:]
			}

			entries.values.forEach {
				entriesSortedByInvalidationDate.insert($0)
				currentSize += $0.valueSize
			}
			scheduleInvalidation()
		}
	}

	private func saveEntries() {
		lock.acquireAndRun {
			let encoder = JSONEncoder()
			let data = try! encoder.encode(entries)
			try! data.write(to: cacheEntriesFileUrl)
		}
	}

	private func url(forCacheIdentifier cacheIdentifier: String) -> URL {
		return cacheDirectoryUrl.appendingPathComponent("/\(MD5(from: Data(cacheIdentifier.utf8)).hex)").standardizedFileURL
	}

	public func value(for key: Key) -> Value? {
		return lock.acquireAndRun {
			if let entry = entries[key.cacheIdentifier] {
				if case let .afterAccess(time) = options.validity {
					if let index = entriesSortedByInvalidationDate.firstIndex(where: { $0.cacheIdentifier == entry.cacheIdentifier }) {
						entriesSortedByInvalidationDate.remove(at: index)
					}
					entry.invalidationDate = scheduler.currentDate.addingTimeInterval(time)
					entriesSortedByInvalidationDate.insert(entry)
					scheduleInvalidation()
				}
				do {
					let data = try Data(contentsOf: url(forCacheIdentifier: entry.cacheIdentifier))
					let value = try serializer.deserialize(data)
					return value
				} catch {
					switch options.serializeErrorBehavior {
					case .noValue:
						return nil
					case let .defaultValue(defaultValue):
						return defaultValue
					case let .handler(handler):
						return handler(key)
					}
				}
			}
			return nil
		}
	}

	public func store(_ value: Value, for key: Key) {
		store(value, for: key.cacheIdentifier)
	}

	private func store(_ value: Value, for cacheIdentifier: String) {
		lock.acquireAndRun {
			invalidateValue(for: cacheIdentifier)
			let data = serializer.serialize(value)

			if let entryCountLimit = options.entryCountLimit, entries.count >= entryCountLimit {
				invalidateValue(for: entriesSortedByInvalidationDate.first!.cacheIdentifier)
			}
			if let totalSizeLimit = options.totalSizeLimit {
				while !entries.isEmpty && currentSize + data.count > totalSizeLimit {
					invalidateValue(for: entriesSortedByInvalidationDate.first!.cacheIdentifier)
				}
			}

			let invalidationDate: Date?
			switch options.validity {
			case .forever:
				invalidationDate = nil
			case let .afterAccess(time), let .afterStorage(time):
				invalidationDate = scheduler.currentDate.addingTimeInterval(time)
			}

			let entry = Entry(cacheIdentifier: cacheIdentifier, valueSize: data.count, validUntil: invalidationDate)
			try! data.write(to: url(forCacheIdentifier: cacheIdentifier))
			entries[cacheIdentifier] = entry
			entriesSortedByInvalidationDate.insert(entry)
			currentSize += data.count
			if entry.invalidationDate != nil {
				scheduleInvalidation()
			}
			saveEntries()
		}
	}

	public func invalidateValue(for key: Key) {
		invalidateValue(for: key.cacheIdentifier)
	}

	private func invalidateValue(for cacheIdentifier: String) {
		lock.acquireAndRun {
			if let entry = entries.removeValue(forKey: cacheIdentifier) {
				try? fileManager.removeItem(at: url(forCacheIdentifier: entry.cacheIdentifier))
				entriesSortedByInvalidationDate.remove(at: entriesSortedByInvalidationDate.firstIndex(where: { $0.cacheIdentifier == cacheIdentifier })!)
				currentSize -= entry.valueSize
			}
			scheduleInvalidation()
			saveEntries()
		}
	}

	public func invalidateAllValues() {
		lock.acquireAndRun {
			entries.values.forEach {
				try? fileManager.removeItem(at: url(forCacheIdentifier: $0.cacheIdentifier))
			}
			entries.removeAll()
			entriesSortedByInvalidationDate.removeAll()
			currentSize = 0
			scheduleInvalidation()
			saveEntries()
		}
	}

	private func scheduleInvalidation() {
		lock.acquireAndRun {
			scheduledInvalidation?.workItem.cancel()
			scheduledInvalidation = nil

			guard let entry = entriesSortedByInvalidationDate.first, let invalidationDate = entry.invalidationDate else { return }
			let workItem = DispatchWorkItem { [weak self, cacheIdentifier = entry.cacheIdentifier] in
				self?.invalidateValue(for: cacheIdentifier)
			}
			scheduledInvalidation = (cacheIdentifier: entry.cacheIdentifier, workItem: workItem)
			scheduler.schedule(at: invalidationDate, execute: workItem)
		}
	}

	public static func == (lhs: OnDiskCache<Key, Serializer>, rhs: OnDiskCache<Key, Serializer>) -> Bool {
		return lhs === rhs
	}
}
#endif
