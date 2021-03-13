//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol EmptyInitializableCollection: Collection {
	init()
}

public extension Collection {
	var nonEmpty: Self? {
		return isEmpty ? nil : self
	}
}

public extension Optional where Wrapped: Collection {
	var isEmpty: Bool {
		return self?.isEmpty != false
	}

	var nonEmpty: Wrapped? {
		switch self {
		case let .some(collection):
			return collection.nonEmpty
		case .none:
			return nil
		}
	}
}

public extension Optional where Wrapped: EmptyInitializableCollection {
	var nonNil: Wrapped {
		switch self {
		case let .some(collection):
			return collection
		case .none:
			return .init()
		}
	}
}

extension String: EmptyInitializableCollection {}

extension Set: EmptyInitializableCollection {
	/// Toggles an element in the Set (that is, if the element exists in the Set, it gets removed from it; otherwise it gets inserted).
	/// - Returns: Whether the set contains the element after the operation.
	@discardableResult
	public mutating func toggle(_ element: Element) -> Bool {
		if contains(element) {
			remove(element)
			return false
		} else {
			insert(element)
			return true
		}
	}
}

public enum DictionaryMergePolicy {
	case keepCurrent, overwrite
}

extension Dictionary: EmptyInitializableCollection {
	public mutating func computeIfAbsent(for key: Key, initializer: @autoclosure () throws -> Value) rethrows -> Value {
		return try computeIfAbsent(for: key) { _ in try initializer() }
	}

	public mutating func computeIfAbsent(for key: Key, initializer: (_ key: Key) throws -> Value) rethrows -> Value {
		if let value = self[key] {
			return value
		}

		let value = try initializer(key)
		self[key] = value
		return value
	}

	public mutating func merge(_ other: [Key: Value], withMergePolicy mergePolicy: DictionaryMergePolicy) {
		merge(other, uniquingKeysWith: { current, new in
			switch mergePolicy {
			case .keepCurrent:
				return current
			case .overwrite:
				return new
			}
		})
	}

	public func merging(_ other: [Key: Value], withMergePolicy mergePolicy: DictionaryMergePolicy) -> [Key: Value] {
		return merging(other, uniquingKeysWith: { current, new in
			switch mergePolicy {
			case .keepCurrent:
				return current
			case .overwrite:
				return new
			}
		})
	}
}

extension Array: EmptyInitializableCollection {
	@discardableResult
	public mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		if let index = try firstIndex(where: predicate) {
			return remove(at: index)
		} else {
			return nil
		}
	}

	@discardableResult
	public mutating func removeLast(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		if let index = try lastIndex(where: predicate) {
			return remove(at: index)
		} else {
			return nil
		}
	}

	public subscript(optional index: Index) -> Element? {
		return index >= startIndex && index < endIndex ? self[index] : nil
	}
}

public extension Sequence {
	func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
		var count = 0
		try forEach {
			if try predicate($0) {
				count += 1
			}
		}
		return count
	}

	func compactMapFirst<T>(_ mapper: (Element) throws -> T?) rethrows -> T? {
		for element in self {
			if let value = try mapper(element) {
				return value
			}
		}
		return nil
	}

	func ofType<T>(_ type: T.Type) -> [T] {
		return filter { $0 is T }.map { $0 as! T }
	}

	func first<T>(ofType type: T.Type, where closure: ((T) throws -> Bool)? = nil) rethrows -> T? {
		if let closure = closure {
			return try first {
				if let typed = $0 as? T, try closure(typed) {
					return true
				} else {
					return false
				}
			} as? T
		} else {
			return first { $0 is T } as? T
		}
	}

	func sorted<A: Comparable>(by mapper: (Element) throws -> A, _ order: SortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try order.areInOrder(lhs: $0, rhs: $1, mapper: mapper) }
	}

	func sorted<A: Comparable, B: Comparable>(by firstMapper: (Element) throws -> A, _ firstOrder: SortOrder = .ascending, then secondMapper: (Element) throws -> B, _ secondOrder: SortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) }
	}

	func sorted<A: Comparable, B: Comparable, C: Comparable>(by firstMapper: (Element) throws -> A, _ firstOrder: SortOrder = .ascending, then secondMapper: (Element) throws -> B, _ secondOrder: SortOrder = .ascending, then thirdMapper: (Element) throws -> C, _ thirdOrder: SortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) || thirdOrder.areInOrder(lhs: $0, rhs: $1, mapper: thirdMapper) }
	}

	func min<T: Comparable>(by mapper: (Element) throws -> T) rethrows -> Element? {
		return try self.min(by: { try SortOrder.ascending.areInOrder(lhs: $0, rhs: $1, mapper: mapper) })
	}

	func max<T: Comparable>(by mapper: (Element) throws -> T) rethrows -> Element? {
		return try self.max(by: { try SortOrder.ascending.areInOrder(lhs: $0, rhs: $1, mapper: mapper) })
	}
}

public extension BidirectionalCollection {
	func last<T>(ofType type: T.Type, where closure: ((T) throws -> Bool)? = nil) rethrows -> T? {
		if let closure = closure {
			return try last {
				if let typed = $0 as? T, try closure(typed) {
					return true
				} else {
					return false
				}
			} as? T
		} else {
			return last { $0 is T } as? T
		}
	}
}

public enum SortOrder {
	case ascending, descending

	public func areInOrder<Value: Comparable>(lhs: Value, rhs: Value) -> Bool {
		switch self {
		case .ascending:
			return lhs < rhs
		case .descending:
			return lhs > rhs
		}
	}

	public func areInOrder<Root, Value: Comparable>(lhs: Root, rhs: Root, mapper: (Root) throws -> Value) rethrows -> Bool {
		return areInOrder(lhs: try mapper(lhs), rhs: try mapper(rhs))
	}
}

#if canImport(Foundation)
import Foundation

extension Data: EmptyInitializableCollection {}
#endif
