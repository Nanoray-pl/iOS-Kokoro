//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation
import KokoroAsync
import KokoroUtils
import ObjectiveC

public struct InMemoryCacheOptions {
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

	public var validity: Validity
	public var entryCountLimit: Int?
	public var totalSizeLimit: Int?

	public init(validity: Validity = .forever, entryCountLimit: Int? = nil, totalSizeLimit: Int? = nil) {
		self.validity = validity
		self.entryCountLimit = entryCountLimit
		self.totalSizeLimit = totalSizeLimit
	}
}

public class InMemoryCache<Key: Hashable, Value>: Cache {
	private class Entry {
		let key: Key
		let value: Value
		let size: Int
		var invalidationDate: Date?

		init(key: Key, value: Value, size: Int, validUntil: Date?) {
			self.key = key
			self.value = value
			self.size = size
			invalidationDate = validUntil
		}
	}

	public var options = InMemoryCacheOptions(
		validity: .afterAccess(5 * 60), // 5 minutes
		totalSizeLimit: Int(ProcessInfo.processInfo.physicalMemory / 4) // 25% of available RAM
	)

	private let scheduler: Scheduler
	private let sizeFunction: (Value) -> Int
	private let lock: Lock = DefaultLock()

	private var entries = [Key: Entry]()
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
	private var scheduledInvalidation: (key: Key, workItem: DispatchWorkItem)?
	private var currentSize = 0

	public init(scheduler: Scheduler = DispatchQueue.global(qos: .background), sizeFunction: @escaping (Value) -> Int) {
		self.scheduler = scheduler
		self.sizeFunction = sizeFunction
	}

	public func value(for key: Key) -> Value? {
		return lock.acquireAndRun {
			if let entry = entries[key] {
				if case let .afterAccess(time) = options.validity {
					if let index = entriesSortedByInvalidationDate.firstIndex(where: { $0.key == entry.key }) {
						entriesSortedByInvalidationDate.remove(at: index)
					}
					entry.invalidationDate = scheduler.currentDate.addingTimeInterval(time)
					entriesSortedByInvalidationDate.insert(entry)
					scheduleInvalidation()
				}
				return entry.value
			}
			return nil
		}
	}

	public func store(_ value: Value, for key: Key) {
		lock.acquireAndRun {
			invalidateValue(for: key)
			let size = sizeFunction(value)

			if let entryCountLimit = self.options.entryCountLimit, entries.count >= entryCountLimit {
				invalidateValue(for: entriesSortedByInvalidationDate.first!.key)
			}
			if let totalSizeLimit = self.options.totalSizeLimit {
				while !entries.isEmpty && currentSize + size > totalSizeLimit {
					invalidateValue(for: entriesSortedByInvalidationDate.first!.key)
				}
			}

			let invalidationDate: Date?
			switch self.options.validity {
			case .forever:
				invalidationDate = nil
			case let .afterAccess(time), let .afterStorage(time):
				invalidationDate = scheduler.currentDate.addingTimeInterval(time)
			}

			let entry = Entry(key: key, value: value, size: size, validUntil: invalidationDate)
			entries[key] = entry
			entriesSortedByInvalidationDate.insert(entry)
			currentSize += size
			if entry.invalidationDate != nil {
				scheduleInvalidation()
			}
		}
	}

	public func invalidateValue(for key: Key) {
		lock.acquireAndRun {
			if let entry = entries.removeValue(forKey: key) {
				entriesSortedByInvalidationDate.remove(at: entriesSortedByInvalidationDate.firstIndex(where: { $0.key == key })!)
				currentSize -= entry.size
			}
			scheduleInvalidation()
		}
	}

	public func invalidateAllValues() {
		lock.acquireAndRun {
			entries.removeAll()
			entriesSortedByInvalidationDate.removeAll()
			currentSize = 0
			scheduleInvalidation()
		}
	}

	private func scheduleInvalidation() {
		lock.acquireAndRun {
			scheduledInvalidation?.workItem.cancel()
			scheduledInvalidation = nil

			guard let entry = entriesSortedByInvalidationDate.first, let invalidationDate = entry.invalidationDate else { return }
			let workItem = DispatchWorkItem { [weak self, key = entry.key] in
				self?.invalidateValue(for: key)
			}
			scheduledInvalidation = (key: entry.key, workItem: workItem)
			scheduler.schedule(at: invalidationDate, execute: workItem)
		}
	}

	public static func == (lhs: InMemoryCache<Key, Value>, rhs: InMemoryCache<Key, Value>) -> Bool {
		return lhs === rhs
	}
}
#endif
