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

	mutating func computeIfAbsent(for key: Key, initializer: @autoclosure () -> Value) -> Value {
		return computeIfAbsent(for: key) { _ in initializer() }
	}

	mutating func computeIfAbsent(for key: Key, initializer: (_ key: Key) -> Value) -> Value {
		if let value = self[key] {
			return value
		}

		let value = initializer(key)
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

private func areInOrder<Element, Value: Comparable>(_ order: KeyPathSortOrder, lhs: Element, rhs: Element, getter: (Element) -> Value) -> Bool {
	switch order {
	case .ascending:
		return getter(lhs) < getter(rhs)
	case .descending:
		return getter(lhs) > getter(rhs)
	}
}

private extension KeyPath where Value: Comparable {
	func areInOrder(_ order: KeyPathSortOrder, lhs: Root, rhs: Root) -> Bool {
		return KokoroUtils.areInOrder(order, lhs: lhs, rhs: rhs) { $0[keyPath: self] }
	}
}

public extension Array {
	func sorted<A: Comparable>(by keyPath: KeyPath<Element, A>, _ order: KeyPathSortOrder = .ascending) -> [Element] {
		return sorted { keyPath.areInOrder(order, lhs: $0, rhs: $1) }
	}

	func sorted<A: Comparable, B: Comparable>(by firstKeyPath: KeyPath<Element, A>, _ firstOrder: KeyPathSortOrder = .ascending, then secondKeyPath: KeyPath<Element, B>, _ secondOrder: KeyPathSortOrder = .ascending) -> [Element] {
		return sorted { firstKeyPath.areInOrder(firstOrder, lhs: $0, rhs: $1) || secondKeyPath.areInOrder(secondOrder, lhs: $0, rhs: $1) }
	}

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
	func min<T: Comparable>(by mapper: (Element) -> T) -> Element? {
		return self.min(by: { areInOrder(.ascending, lhs: $0, rhs: $1, getter: mapper) })
	}

	func max<T: Comparable>(by mapper: (Element) -> T) -> Element? {
		return self.max(by: { areInOrder(.ascending, lhs: $0, rhs: $1, getter: mapper) })
	}

	func min<A: Comparable>(by keyPath: KeyPath<Element, A>) -> Element? {
		return self.min(by: { keyPath.areInOrder(.ascending, lhs: $0, rhs: $1) })
	}

	func max<A: Comparable>(by keyPath: KeyPath<Element, A>) -> Element? {
		return self.max(by: { keyPath.areInOrder(.ascending, lhs: $0, rhs: $1) })
	}
}

public enum KeyPathSortOrder {
	case ascending, descending
}
