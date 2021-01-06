//
//  Created on 31/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol CollectionDiffStrategy {
	associatedtype Element
	associatedtype Change: CollectionDiffChange

	func difference<InitialCollection, FinalCollection>(between initial: InitialCollection, and final: FinalCollection) -> CollectionDiff<Element, Change> where InitialCollection: BidirectionalCollection, FinalCollection: BidirectionalCollection, InitialCollection.Element == Element, FinalCollection.Element == Element
}

public protocol CollectionDiffChange {
	associatedtype Element

	func apply(to array: [Element]) -> [Element]
}

public struct CollectionDiff<Element, Change>: BidirectionalCollection where Change: CollectionDiffChange, Change.Element == Element {
	public var changes: [Change]

	public var startIndex: Int {
		return changes.startIndex
	}

	public var endIndex: Int {
		return changes.endIndex
	}

	public subscript(position: Int) -> Change {
		return changes[position]
	}

	public init(changes: [Change]) {
		self.changes = changes
	}

	public func index(before i: Int) -> Int {
		return i - 1
	}

	public func index(after i: Int) -> Int {
		return i + 1
	}

	public func apply(to array: [Element]) -> [Element] {
		var result = array
		changes.forEach { result = $0.apply(to: result) }
		return result
	}

	public func eraseToAnyCollectionDiff() -> AnyCollectionDiff<Element> {
		return .init(wrapping: self)
	}
}

public struct AnyCollectionDiff<Element> {
	private let applyClosure: (_ array: [Element]) -> [Element]
	private let countClosure: () -> Int

	public var count: Int {
		return countClosure()
	}

	public init<Change>(wrapping wrapped: CollectionDiff<Element, Change>) {
		applyClosure = { wrapped.apply(to: $0) }
		countClosure = { wrapped.count }
	}

	public func apply(to array: [Element]) -> [Element] {
		return applyClosure(array)
	}
}

public extension Array {
	func difference<InitialCollection, Strategy>(from other: InitialCollection, via strategy: Strategy) -> CollectionDiff<Strategy.Element, Strategy.Change> where InitialCollection: BidirectionalCollection, Strategy: CollectionDiffStrategy, InitialCollection.Element == Element, Strategy.Element == Element {
		return strategy.difference(between: self, and: other)
	}
}
