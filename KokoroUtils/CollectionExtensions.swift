//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public extension Set {
	/// Toggles an element in the Set (that is, if the element exists in the Set, it gets removed from it; otherwise it gets inserted). Returns whether the set contains the element after the operation.
	@discardableResult
	mutating func toggle(_ element: Element) -> Bool {
		if contains(element) {
			remove(element)
			return false
		} else {
			insert(element)
			return true
		}
	}
}

public extension Dictionary {
	enum MergePolicy {
		case keepCurrent, overwrite
	}

	mutating func computeIfAbsent(for key: Key, initializer: @autoclosure () throws -> Value) rethrows -> Value {
		return try computeIfAbsent(for: key) { _ in try initializer() }
	}

	mutating func computeIfAbsent(for key: Key, initializer: (_ key: Key) throws -> Value) rethrows -> Value {
		if let value = self[key] {
			return value
		}

		let value = try initializer(key)
		self[key] = value
		return value
	}

	func merging(_ other: [Key: Value], withMergePolicy mergePolicy: MergePolicy) -> [Key: Value] {
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

public extension Collection {
	func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
		var count = 0
		try forEach {
			if try predicate($0) {
				count += 1
			}
		}
		return count
	}
}

public extension Array {
	@discardableResult
	mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		if let index = try firstIndex(where: predicate) {
			return remove(at: index)
		} else {
			return nil
		}
	}

	@discardableResult
	mutating func removeLast(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		if let index = try lastIndex(where: predicate) {
			return remove(at: index)
		} else {
			return nil
		}
	}
}

public extension Sequence {
	func sorted<A: Comparable>(by mapper: (Element) throws -> A, _ order: KeyPathSortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try order.areInOrder(lhs: $0, rhs: $1, mapper: mapper) }
	}

	func sorted<A: Comparable, B: Comparable>(by firstMapper: (Element) throws -> A, _ firstOrder: KeyPathSortOrder = .ascending, then secondMapper: (Element) throws -> B, _ secondOrder: KeyPathSortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) }
	}

	func sorted<A: Comparable, B: Comparable, C: Comparable>(by firstMapper: (Element) throws -> A, _ firstOrder: KeyPathSortOrder = .ascending, then secondMapper: (Element) throws -> B, _ secondOrder: KeyPathSortOrder = .ascending, then thirdMapper: (Element) throws -> C, _ thirdOrder: KeyPathSortOrder = .ascending) rethrows -> [Element] {
		return try sorted { try firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) || thirdOrder.areInOrder(lhs: $0, rhs: $1, mapper: thirdMapper) }
	}

	func min<T: Comparable>(by mapper: (Element) throws -> T) rethrows -> Element? {
		return try self.min(by: { try KeyPathSortOrder.ascending.areInOrder(lhs: $0, rhs: $1, mapper: mapper) })
	}

	func max<T: Comparable>(by mapper: (Element) throws -> T) rethrows -> Element? {
		return try self.max(by: { try KeyPathSortOrder.ascending.areInOrder(lhs: $0, rhs: $1, mapper: mapper) })
	}
}

public enum KeyPathSortOrder {
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
