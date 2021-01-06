//
//  Created on 31/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public class InsertionRemovalMoveCollectionDiffStrategy<Element>: CollectionDiffStrategy {
	public enum Change: CollectionDiffChange {
		case insert(index: Int, element: Element)
		case remove(index: Int, element: Element)
		case move(sourceIndex: Int, destinationIndex: Int, element: Element)

		public func apply(to array: [Element]) -> [Element] {
			var result = array
			switch self {
			case let .insert(index, element):
				result.insert(element, at: index)
			case let .remove(index, _):
				result.remove(at: index)
			case let .move(sourceIndex, destinationIndex, element):
				result.remove(at: sourceIndex)
				result.insert(element, at: destinationIndex)
			}
			return result
		}
	}

	private struct Iterable<Iterator> where Iterator: IteratorProtocol, Iterator.Element == Element {
		private(set) var iterator: Iterator
		private(set) var element: Element?
		private(set) var index: Int = 0

		mutating func next() {
			index += 1
			element = iterator.next()
		}
	}

	private let predicate: (Element, Element) -> Bool

	public init(predicate: @escaping (Element, Element) -> Bool) {
		self.predicate = predicate
	}

	public func difference<InitialCollection, FinalCollection>(between initial: InitialCollection, and final: FinalCollection) -> CollectionDiff<Element, Change> where InitialCollection: BidirectionalCollection, FinalCollection: BidirectionalCollection, InitialCollection.Element == Element, FinalCollection.Element == Element {
		var inserted = final.filter { finalElement in !initial.contains { predicate($0, finalElement) } }
		var removed = initial.filter { initialElement in !final.contains { predicate($0, initialElement) } }

		var changes = [Change]()
		var initialIterable = Iterable(iterator: initial.makeIterator())
		var finalIterable = Iterable(iterator: final.makeIterator())

		while initialIterable.element != nil || finalIterable.element != nil {
			switch (initialIterable.element, finalIterable.element) {
			case let (initialElement?, finalElement?):
				if predicate(initialElement, finalElement) {
					initialIterable.next()
					finalIterable.next()
					break
				} else if let insertedIndex = inserted.firstIndex(where: { predicate($0, finalElement) }) {
					changes.append(.insert(index: finalIterable.index, element: finalElement))
					finalIterable.next()
					inserted.remove(at: insertedIndex)
				} else if let removedIndex = removed.firstIndex(where: { predicate($0, initialElement) }) {
					changes.append(.remove(index: initialIterable.index, element: initialElement))
					initialIterable.next()
					removed.remove(at: removedIndex)
				} else {
					fatalError("Invalid state")
				}
			case let (initialElement?, nil):
				changes.append(.remove(index: initialIterable.index, element: initialElement))
				initialIterable.next()
				removed.removeFirst(where: { predicate($0, initialElement) })
			case let (nil, finalElement?):
				changes.append(.insert(index: finalIterable.index, element: finalElement))
				finalIterable.next()
				inserted.removeFirst(where: { predicate($0, finalElement) })
			case (nil, nil):
				fatalError("Invalid state")
			}
		}
		return .init(changes: changes)
	}
}

public extension InsertionRemovalMoveCollectionDiffStrategy where Element: Equatable {
	convenience init() {
		self.init { $0 == $1 }
	}
}
