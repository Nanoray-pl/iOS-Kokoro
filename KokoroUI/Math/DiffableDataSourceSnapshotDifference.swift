//
//  Created on 31/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public struct DiffableDataSourceSnapshotDifference<Section: Hashable, Item: Hashable>: BidirectionalCollection, ExpressibleByArrayLiteral {
	public enum Change: Equatable {
		case insert(section: Section, index: Int, element: Item)
		case remove(section: Section, index: Int, element: Item)
		case move(section: Section, sourceIndex: Int, destinationIndex: Int, element: Item)
		case insertSection(section: Section, index: Int, elements: [Item])
		case removeSection(section: Section, index: Int)
		case moveSection(section: Section, sourceIndex: Int, destinationIndex: Int)
	}

	private let changes: [Change]

	public var startIndex: Int {
		return 0
	}

	public var endIndex: Int {
		return changes.count
	}

	public var count: Int {
		return changes.count
	}

	public var isEmpty: Bool {
		return changes.isEmpty
	}

	public subscript(position: Int) -> Change {
		return changes[position]
	}

	public init(changes: [Change]) {
		self.changes = changes
	}

	public init(arrayLiteral elements: Change...) {
		changes = elements
	}

	public func index(before i: Int) -> Int {
		return i - 1
	}

	public func index(after i: Int) -> Int {
		return i + 1
	}
}

public extension NSDiffableDataSourceSnapshot {
	private struct Section<ID: Hashable, Item: Hashable> {
		let identifier: ID
		let items: [Item]

		init(identifier: ID, items: [Item]) {
			self.identifier = identifier
			self.items = items
		}

		init(from snapshot: NSDiffableDataSourceSnapshot<ID, Item>, identifier: ID) {
			self.identifier = identifier
			items = snapshot.itemIdentifiers(inSection: identifier)
		}
	}

	func diffableDifference(from other: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) -> DiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType> {
		let before = sectionIdentifiers.map { Section(from: self, identifier: $0) }
		let after = sectionIdentifiers.map { Section(from: other, identifier: $0) }

		var insertedSections = after.filter { afterSection in !before.contains { $0.identifier == afterSection.identifier } }
		var removedSections = before.filter { beforeSection in !after.contains { $0.identifier == beforeSection.identifier } }
		let existingSections = after.filter { afterSection in before.contains { $0.identifier == afterSection.identifier } }

		var changes = [DiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>.Change]()
		var beforeSectionIndex = 0
		var afterSectionIndex = 0

		while beforeSectionIndex < before.count && afterSectionIndex < after.count {
			if let beforeSection = before[optional: beforeSectionIndex], let afterSection = after[optional: afterSectionIndex] {
				if beforeSection.identifier == afterSection.identifier {
					beforeSectionIndex += 1
					afterSectionIndex += 1
				} else if insertedSections.contains(where: { $0.identifier == afterSection.identifier }) {
					changes.append(.insertSection(section: afterSection.identifier, index: afterSectionIndex, elements: afterSection.items))
					afterSectionIndex += 1
					insertedSections.removeFirst { $0.identifier == afterSection.identifier }
				} else if removedSections.contains(where: { $0.identifier == beforeSection.identifier }) {
					changes.append(.removeSection(section: beforeSection.identifier, index: beforeSectionIndex))
					beforeSectionIndex += 1
					removedSections.removeFirst { $0.identifier == beforeSection.identifier }
				} else {
					fatalError("Invalid state")
				}
			} else if let afterSection = after[optional: afterSectionIndex] {
				changes.append(.insertSection(section: afterSection.identifier, index: afterSectionIndex, elements: afterSection.items))
				afterSectionIndex += 1
				insertedSections.removeFirst { $0.identifier == afterSection.identifier }
			} else if let beforeSection = before[optional: beforeSectionIndex] {
				changes.append(.removeSection(section: beforeSection.identifier, index: beforeSectionIndex))
				beforeSectionIndex += 1
				removedSections.removeFirst { $0.identifier == beforeSection.identifier }
			} else {
				fatalError("Invalid state")
			}
		}

		for afterSection in existingSections {
			let beforeSection = before.first { $0.identifier == afterSection.identifier }!
			var insertedItems = afterSection.items.filter { afterItem in !beforeSection.items.contains { $0 == afterItem } }
			var removedItems = beforeSection.items.filter { beforeItem in !afterSection.items.contains { $0 == beforeItem } }
			var beforeIndex = 0
			var afterIndex = 0

			while beforeIndex < beforeSection.items.count && afterIndex < afterSection.items.count {
				if let beforeItem = beforeSection.items[optional: beforeIndex], let afterItem = afterSection.items[optional: afterIndex] {
					if beforeItem == afterItem {
						beforeIndex += 1
						afterIndex += 1
					} else if insertedItems.contains(where: { $0 == afterItem }) {
						changes.append(.insert(section: afterSection.identifier, index: afterIndex, element: afterItem))
						afterIndex += 1
						insertedItems.removeFirst { $0 == afterItem }
					} else if removedItems.contains(where: { $0 == beforeItem }) {
						changes.append(.remove(section: beforeSection.identifier, index: beforeIndex, element: beforeItem))
						beforeIndex += 1
						removedItems.removeFirst { $0 == beforeItem }
					} else {
						fatalError("Invalid state")
					}
				} else if let afterItem = afterSection.items[optional: afterIndex] {
					changes.append(.insert(section: afterSection.identifier, index: afterIndex, element: afterItem))
					afterIndex += 1
					insertedItems.removeFirst { $0 == afterItem }
				} else if let beforeItem = beforeSection.items[optional: beforeIndex] {
					changes.append(.remove(section: beforeSection.identifier, index: beforeIndex, element: beforeItem))
					beforeIndex += 1
					removedItems.removeFirst { $0 == beforeItem }
				} else {
					fatalError("Invalid state")
				}
			}
		}

		return .init(changes: changes)
	}
}
#endif
