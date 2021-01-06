//
//  Created on 31/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public class InsertionRemovalCollectionDiffStrategy<Element>: CollectionDiffStrategy {
	public typealias Change = CollectionDifference<Element>.Change

	private let predicate: (Element, Element) -> Bool

	public init(predicate: @escaping (Element, Element) -> Bool) {
		self.predicate = predicate
	}

	public func difference<InitialCollection, FinalCollection>(between initial: InitialCollection, and final: FinalCollection) -> CollectionDiff<Element, Change> where InitialCollection: BidirectionalCollection, FinalCollection: BidirectionalCollection, InitialCollection.Element == Element, FinalCollection.Element == Element {
		return .init(changes: Array(final.difference(from: initial, by: predicate)))
	}
}

extension CollectionDifference.Change: CollectionDiffChange {
	public typealias Element = ChangeElement

	public func apply(to array: [ChangeElement]) -> [ChangeElement] {
		var result = array
		switch self {
		case let .insert(offset, element, _):
			result.insert(element, at: offset)
		case let .remove(offset, _, _):
			result.remove(at: offset)
		}
		return result
	}
}

public extension InsertionRemovalCollectionDiffStrategy where Element: Equatable {
	convenience init() {
		self.init { $0 == $1 }
	}
}
