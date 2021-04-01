//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public struct SortedArray<Element>: BidirectionalCollection {
	public typealias Index = Array<Element>.Index

	private var array: [Element]
	private let comparator: (Element, Element) -> Bool
	private let uniqueValues: Bool

	public var startIndex: Index {
		return array.startIndex
	}

	public var endIndex: Index {
		return array.endIndex
	}

	public init<A: Comparable>(elements: [Element] = [], by mapper: @escaping (Element) -> A, _ order: SortOrder = .ascending) {
		self.init(elements: elements, _uniqueValues: false) { order.areInOrder(lhs: $0, rhs: $1, mapper: mapper) }
	}

	public init<A: Comparable, B: Comparable>(elements: [Element] = [], by firstMapper: @escaping (Element) -> A, _ firstOrder: SortOrder = .ascending, then secondMapper: @escaping (Element) -> B, _ secondOrder: SortOrder = .ascending) {
		self.init(elements: elements, _uniqueValues: false) { firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) }
	}

	public init<A: Comparable, B: Comparable, C: Comparable>(elements: [Element] = [], by firstMapper: @escaping (Element) -> A, _ firstOrder: SortOrder = .ascending, then secondMapper: @escaping (Element) -> B, _ secondOrder: SortOrder = .ascending, then thirdMapper: @escaping (Element) -> C, _ thirdOrder: SortOrder = .ascending) {
		self.init(elements: elements, _uniqueValues: false) { firstOrder.areInOrder(lhs: $0, rhs: $1, mapper: firstMapper) || secondOrder.areInOrder(lhs: $0, rhs: $1, mapper: secondMapper) || thirdOrder.areInOrder(lhs: $0, rhs: $1, mapper: thirdMapper) }
	}

	public init(elements: [Element] = [], comparator: @escaping (Element, Element) -> Bool) {
		self.init(elements: elements, _uniqueValues: false, comparator: comparator)
	}

	fileprivate init(elements: [Element] = [], _uniqueValues: Bool, comparator: @escaping (Element, Element) -> Bool) { // swiftlint:disable:this identifier_name
		self.comparator = comparator
		uniqueValues = _uniqueValues
		array = []

		elements.forEach { insert($0) }
	}

	public subscript(index: Index) -> Element {
		return array[index]
	}

	public func index(after i: Index) -> Index { // swiftlint:disable:this identifier_name
		return array.index(after: i)
	}

	public func index(before i: Index) -> Index { // swiftlint:disable:this identifier_name
		return array.index(before: i)
	}

	public mutating func insert(_ element: Element) {
		for index in array.indices {
			if comparator(element, array[index]) {
				array.insert(element, at: index)
				return
			}
		}
		array.append(element)
	}

	@discardableResult
	public mutating func remove(at index: Index) -> Element? {
		return array.remove(at: index)
	}

	public mutating func removeAll() {
		array.removeAll()
	}

	private static func areEqual<Element>(lhs: Element, rhs: Element, comparator: @escaping (Element, Element) -> Bool) -> Bool {
		return !comparator(lhs, rhs) && !comparator(rhs, lhs)
	}

	private static func isSorted<Element>(_ array: [Element], comparator: @escaping (Element, Element) -> Bool) -> Bool {
		for index in array.indices.dropFirst() {
			if comparator(array[index], array[index - 1]) {
				return false
			}
		}
		return true
	}
}

extension SortedArray: Equatable where Element: Equatable {
	public init(elements: [Element] = [], uniqueValues: Bool = false, comparator: @escaping (Element, Element) -> Bool) {
		self.init(elements: elements, _uniqueValues: uniqueValues, comparator: comparator)
	}

	public mutating func remove(_ element: Element) {
		if let index = array.firstIndex(of: element) {
			array.remove(at: index)
		}
	}

	public static func == (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
		return lhs.array == rhs.array
	}
}

extension SortedArray: Hashable where Element: Hashable {
	public init(elements: [Element] = [], uniqueValues: Bool = false, comparator: @escaping (Element, Element) -> Bool) {
		self.comparator = comparator
		self.uniqueValues = uniqueValues
		if uniqueValues || !Self.isSorted(elements, comparator: comparator) {
			array = Array(Set(elements)).sorted(by: comparator)
		} else {
			array = elements
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(array)
	}
}

extension SortedArray: ExpressibleByArrayLiteral where Element: Comparable {
	public init(arrayLiteral elements: Element...) {
		self.init(elements: elements, comparator: { $0 < $1 })
	}

	public init(elements: [Element] = [], uniqueValues: Bool = false) {
		self.init(elements: elements, uniqueValues: uniqueValues, comparator: { $0 < $1 })
	}
}

public extension SortedArray where Element: Hashable, Element: Comparable {
	init(elements: [Element] = [], uniqueValues: Bool = false) {
		self.init(elements: elements, uniqueValues: uniqueValues, comparator: { $0 < $1 })
	}
}

public extension SortedArray {
	@discardableResult
	mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		if let index = try firstIndex(where: predicate) {
			return remove(at: index)
		} else {
			return nil
		}
	}
}
