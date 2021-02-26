//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public protocol FlexColumnCollectionViewLayoutDelegate: UICollectionViewDelegate {
	/// - Warning: This method can also be called for indexes outside of your data source's bounds when additional layout calculations are requested (for example, when calling `FlexColumnCollectionViewLayout.itemCountToCompletelyFill(additionalRowCount:existingItemCount:inSection:)`).
	func columnConstraint(forRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ColumnConstraint

	func itemRowLength(at indexPath: IndexPath?, inColumn columnIndex: Int, inRow rowIndex: Int, inSection sectionIndex: Int, columnLength: CGFloat, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ItemRowLength
	func sectionSpacing(between precedingSectionIndex: Int, and followingSectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
	func rowSpacing(between precedingRowIndex: Int, and followingRowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat

	/// - Warning: The value returned from this method cannot be smaller than `layout.columnSpacing` - if it is, `layout.columnSpacing` will be used instead.
	func columnSpacing(between preceding: (indexPath: IndexPath?, columnIndex: Int), and following: (indexPath: IndexPath?, columnIndex: Int), inRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
}

public extension FlexColumnCollectionViewLayoutDelegate {
	func columnConstraint(forRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ColumnConstraint {
		return layout.columnConstraint
	}

	func itemRowLength(at indexPath: IndexPath?, inColumn columnIndex: Int, inRow rowIndex: Int, inSection sectionIndex: Int, columnLength: CGFloat, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ItemRowLength {
		return layout.itemRowLength
	}

	func sectionSpacing(between precedingSectionIndex: Int, and followingSectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat {
		return layout.sectionSpacing
	}

	func rowSpacing(between precedingRowIndex: Int, and followingRowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat {
		return layout.rowSpacing
	}

	func columnSpacing(between preceding: (indexPath: IndexPath?, columnIndex: Int), and following: (indexPath: IndexPath?, columnIndex: Int), inRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat {
		return layout.columnSpacing
	}
}

public protocol FlexColumnCollectionViewLayoutObserver: class {
	func didRecalculateLayout(to calculatedLayout: FlexColumnCollectionViewLayout.CalculatedLayout, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView)
}

public class FlexColumnCollectionViewLayout: UICollectionViewLayout {
	private static let contentBackgroundZIndex = -6
	private static let insetContentBackgroundZIndex = -5
	private static let sectionBackgroundZIndex = -4
	private static let rowBackgroundZIndex = -3
	private static let columnBackgroundZIndex = -2
	private static let itemBackgroundZIndex = -1

	public static let contentBackgroundElementKind = UUID().uuidString
	public static let insetContentBackgroundElementKind = UUID().uuidString
	public static let sectionBackgroundElementKind = UUID().uuidString
	public static let rowBackgroundElementKind = UUID().uuidString
	public static let columnBackgroundElementKind = UUID().uuidString
	public static let itemBackgroundElementKind = UUID().uuidString

	public enum ColumnConstraint: Equatable, ExpressibleByIntegerLiteral {
		case count(_ count: Int)
		case minLength(_ minLength: CGFloat)

		public init(integerLiteral value: IntegerLiteralType) {
			self = .count(value)
		}
	}

	public enum ItemRowLength: Equatable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
		case fixed(_ length: CGFloat)
		case ratio(_ ratio: CGFloat)

		public init(integerLiteral value: IntegerLiteralType) {
			self = .fixed(CGFloat(value))
		}

		public init(floatLiteral value: FloatLiteralType) {
			self = .fixed(CGFloat(value))
		}
	}

	public enum Orientation: Hashable {
		public enum FillDirection {
			public enum Vertical {
				case leftToRight, rightToLeft
			}

			public enum Horizontal {
				case topToBottom, bottomToTop
			}
		}

		public enum LastColumnAlignment {
			public enum Vertical: Hashable {
				case left, center, right, fillEqually(maxItemsToRedistributePerRow: Int = 0)
			}

			public enum Horizontal: Hashable {
				case top, center, bottom, fillEqually(maxItemsToRedistributePerRow: Int = 0)
			}
		}

		public enum ItemDistribution {
			public enum Vertical {
				case top, center, bottom, fill
			}

			public enum Horizontal {
				case left, center, right, fill
			}
		}

		case vertical(fillDirection: FillDirection.Vertical = .leftToRight, lastColumnAlignment: LastColumnAlignment.Vertical = .left, itemDistribution: ItemDistribution.Vertical = .top)
		case horizontal(fillDirection: FillDirection.Horizontal = .topToBottom, lastColumnAlignment: LastColumnAlignment.Horizontal = .top, itemDistribution: ItemDistribution.Horizontal = .left)
	}

	public struct BackgroundConfig: Equatable {
		public var content = EnablementState.disabled
		public var insetContent = EnablementState.disabled
		public var section = EnablementState.disabled
		public var row = EnablementState.disabled

		/// - Warning: A column background will only be used if `orientation.lastColumnAlignment` is `.left`, `.right`, `.top` or `.bottom` and if all rows have the same number of (used or not) columns (via either the same `columnConstraint`, or a `columnConstraint` which results in the same number of columns for all of the rows) and if all corresponding `columnSpacing`s are the same.
		public var column = EnablementState.disabled

		public var item = EnablementState.disabled
	}

	public enum SupplementaryView: Equatable {
		case contentBackground
		case insetContentBackground
		case sectionBackground(index: Int)
		case rowBackground(sectionIndex: Int, rowIndex: Int)
		case columnBackground(sectionIndex: Int, columnIndex: Int)
		case itemBackground(indexPath: IndexPath)
	}

	public struct CalculatedLayout: Equatable {
		public struct Section: Equatable {
			public let index: Int
			public let rows: [Row]
			public let rowSpacings: [CGFloat]
		}

		public struct Row: Equatable {
			public let index: Int
			public let rowLength: CGFloat
			public let maxColumnCount: Int
			public let isFillingEqually: Bool
			public let columnLength: CGFloat
			public let cells: [Cell]
			public let columnSpacings: [CGFloat]
			public let columnOffset: CGFloat

			fileprivate var rowAttributes: RowAttributes {
				return .init(columnCount: cells.count, columnLength: columnLength)
			}

			public var additionalItemCountToCompletelyFillRow: Int {
				return maxColumnCount - cells.count
			}
		}

		public struct Cell: Equatable {
			public let columnIndex: Int
			public let indexPath: IndexPath?
			public let rowLength: CGFloat
			public let rowOffset: CGFloat
		}

		public let sections: [Section]
		public let sectionSpacings: [CGFloat]
		public let rowLength: CGFloat
		public let defaultColumnCount: Int
		public let defaultColumnLength: CGFloat
	}

	fileprivate struct RowAttributes: Equatable {
		let columnCount: Int
		let columnLength: CGFloat
	}

	private struct RowIndexPath: Hashable {
		let section: Int
		let row: Int
	}

	private struct ColumnIndexPath: Hashable {
		let section: Int
		let column: Int
	}

	public var contentInsets = UIEdgeInsets.zero {
		didSet {
			if oldValue == contentInsets { return }
			invalidateLayout()
		}
	}

	public var orientation = Orientation.vertical() {
		didSet {
			if oldValue == orientation { return }
			invalidateLayout()
		}
	}

	public var columnConstraint = ColumnConstraint.minLength(150) {
		didSet {
			if oldValue == columnConstraint { return }
			invalidateLayout()
		}
	}

	public var columnSpacing: CGFloat = 0 {
		didSet {
			if oldValue == columnSpacing { return }
			invalidateLayout()
		}
	}

	public var rowSpacing: CGFloat = 0 {
		didSet {
			if oldValue == rowSpacing { return }
			invalidateLayout()
		}
	}

	public var sectionSpacing: CGFloat = 20 {
		didSet {
			if oldValue == sectionSpacing { return }
			invalidateLayout()
		}
	}

	public var itemRowLength = ItemRowLength.ratio(1) {
		didSet {
			if oldValue == itemRowLength { return }
			invalidateLayout()
		}
	}

	public var backgrounds = BackgroundConfig() {
		didSet {
			if oldValue == backgrounds { return }
			invalidateLayout()
		}
	}

	public var calculatedLayout: CalculatedLayout {
		if let calculatedLayout = calculatedLayoutStorage {
			return calculatedLayout
		} else {
			let calculatedLayout = calculateLayout()
			calculatedLayoutStorage = calculatedLayout
			return calculatedLayout
		}
	}

	private var isLayoutInvalidated = true
	private var calculatedContentLength: CGFloat = 0
	private var attributes = [IndexPath: UICollectionViewLayoutAttributes]()
	private var contentBackgroundAttribute: UICollectionViewLayoutAttributes?
	private var insetContentBackgroundAttribute: UICollectionViewLayoutAttributes?
	private var sectionBackgroundAttributes = [UICollectionViewLayoutAttributes]()
	private var rowBackgroundAttributes = [RowIndexPath: UICollectionViewLayoutAttributes]()
	private var columnBackgroundAttributes = [ColumnIndexPath: UICollectionViewLayoutAttributes]()
	private var itemBackgroundAttributes = [IndexPath: UICollectionViewLayoutAttributes]()

	private var allAttributes: [UICollectionViewLayoutAttributes] {
		var attributes = [UICollectionViewLayoutAttributes]()
		attributes.append(contentsOf: [contentBackgroundAttribute, insetContentBackgroundAttribute].compactMap { $0 })
		attributes.append(contentsOf: sectionBackgroundAttributes)
		attributes.append(contentsOf: rowBackgroundAttributes.values)
		attributes.append(contentsOf: columnBackgroundAttributes.values)
		attributes.append(contentsOf: itemBackgroundAttributes.values)
		attributes.append(contentsOf: self.attributes.values)
		return attributes
	}

	private var calculatedLayoutStorage: CalculatedLayout? {
		didSet {
			if oldValue == calculatedLayoutStorage { return }
			guard let layout = calculatedLayoutStorage, let collectionView = collectionView else { return }
			observers.forEach { $0.didRecalculateLayout(to: layout, in: self, in: collectionView) }
		}
	}

	private let observers = BoxingObserverSet<FlexColumnCollectionViewLayoutObserver, Void>()

	private var delegate: FlexColumnCollectionViewLayoutDelegate? {
		return collectionView?.delegate as? FlexColumnCollectionViewLayoutDelegate
	}

	public override var collectionViewContentSize: CGSize {
		return .init(
			width: orientational(vertical: collectionView?.bounds.width ?? 0, horizontal: calculatedContentLength),
			height: orientational(vertical: calculatedContentLength, horizontal: collectionView?.bounds.height ?? 0)
		)
	}

	private func orientational<Value>(vertical: @autoclosure () -> Value, horizontal: @autoclosure () -> Value) -> Value {
		switch orientation {
		case .vertical:
			return vertical()
		case .horizontal:
			return horizontal()
		}
	}

	private func orientational<Root, Value>(_ root: Root, vertical: (Root) -> Value, horizontal: (Root) -> Value) -> Value {
		switch orientation {
		case .vertical:
			return vertical(root)
		case .horizontal:
			return horizontal(root)
		}
	}

	private func availableColumnLength() -> CGFloat {
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
		return orientational(collectionView.bounds, vertical: \.width, horizontal: \.height) - orientational(contentInsets, vertical: \.horizontal, horizontal: \.vertical)
	}

	private func calculateRowAttributes(availableColumnLength: CGFloat, columnConstraint: ColumnConstraint) -> RowAttributes {
		switch columnConstraint {
		case let .count(columnCount):
			let columnLength = self.columnLength(forColumnCount: columnCount, availableColumnLength: availableColumnLength)
			return .init(columnCount: columnCount, columnLength: columnLength)
		case let .minLength(minColumnLength):
			let columnCount = self.columnCount(forColumnLength: minColumnLength, availableColumnLength: availableColumnLength)
			let columnLength = self.columnLength(forColumnCount: columnCount, availableColumnLength: availableColumnLength)
			return .init(columnCount: columnCount, columnLength: columnLength)
		}
	}

	private func columnLength(forColumnCount columnCount: Int, availableColumnLength: CGFloat) -> CGFloat {
		return columnLength(forColumnCount: columnCount, availableColumnLength: availableColumnLength, columnSpacings: Array(repeating: columnSpacing, count: columnCount - 1))
	}

	private func columnLength(forColumnCount columnCount: Int, availableColumnLength: CGFloat, columnSpacings: [CGFloat]) -> CGFloat {
		return (availableColumnLength - columnSpacings.reduce(0, +)) / CGFloat(columnCount)
	}

	private func columnCount(forColumnLength columnLength: CGFloat, availableColumnLength: CGFloat) -> Int {
		return max(Int((availableColumnLength + columnSpacing) / columnLength), 1)
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let collectionView = collectionView else { return true }
		return collectionView.frame.size != newBounds.size
	}

	public override func invalidateLayout() {
		super.invalidateLayout()
		isLayoutInvalidated = true
	}

	private func shouldRecalculateLayout() -> Bool {
		if isLayoutInvalidated { return true }
		if let layout = calculatedLayoutStorage {
			guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
			return (0 ..< layout.sections.count).contains { sectionIndex in layout.sections[sectionIndex].rows.flatMap { $0.cells.map(\.indexPath) }.count != collectionView.numberOfItems(inSection: sectionIndex) }
		} else {
			return true
		}
	}

	private func recalculateLayoutIfNeeded(prepare: Bool) {
		if shouldRecalculateLayout() {
			calculatedLayoutStorage = calculateLayout()
			isLayoutInvalidated = false
			if prepare {
				self.prepare()
			}
		}
	}

	// swiftlint:disable:next cyclomatic_complexity
	public override func prepare() {
		super.prepare()
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
		recalculateLayoutIfNeeded(prepare: false)
		attributes.removeAll()
		contentBackgroundAttribute = nil
		insetContentBackgroundAttribute = nil
		sectionBackgroundAttributes.removeAll()
		rowBackgroundAttributes.removeAll()
		columnBackgroundAttributes.removeAll()
		itemBackgroundAttributes.removeAll()

		let layout = calculatedLayout
		let leadingColumnOffset = orientational(contentInsets, vertical: \.left, horizontal: \.top)
		let leadingRowOffset = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		var currentRowOffset = leadingRowOffset

		for sectionIndex in 0 ..< layout.sections.count {
			if sectionIndex > 0 {
				currentRowOffset += layout.sectionSpacings[sectionIndex - 1]
			}
			let section = layout.sections[sectionIndex]
			let sectionRowOffset = currentRowOffset

			for rowIndex in 0 ..< section.rows.count {
				if rowIndex > 0 {
					currentRowOffset += section.rowSpacings[rowIndex - 1]
				}
				let row = section.rows[rowIndex]

				var currentColumnOffset = row.columnOffset
				for columnIndex in 0 ..< row.cells.count {
					if columnIndex > 0 {
						currentColumnOffset += row.columnSpacings[columnIndex - 1]
					}
					let cell = row.cells[columnIndex]
					if let indexPath = cell.indexPath {
						let frameColumnOffset = leadingColumnOffset + currentColumnOffset
						let frameRowOffset = currentRowOffset + cell.rowOffset
						let attributeFrame = CGRect(
							x: orientational(vertical: frameColumnOffset, horizontal: frameRowOffset),
							y: orientational(vertical: frameRowOffset, horizontal: frameColumnOffset),
							width: orientational(vertical: row.columnLength, horizontal: cell.rowLength),
							height: orientational(vertical: cell.rowLength, horizontal: row.columnLength)
						)
						attributes[indexPath] = UICollectionViewLayoutAttributes(forCellWith: indexPath).with {
							$0.frame = attributeFrame
						}
						if backgrounds.item == .enabled {
							itemBackgroundAttributes[indexPath] = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.itemBackgroundElementKind, with: indexPath).with {
								$0.frame = attributeFrame
								$0.zIndex = Self.itemBackgroundZIndex
							}
						}
					}
					currentColumnOffset += row.columnLength
				}

				if backgrounds.row == .enabled {
					rowBackgroundAttributes[.init(section: sectionIndex, row: rowIndex)] = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.rowBackgroundElementKind, with: .init(item: rowIndex, section: sectionIndex)).with {
						$0.frame = .init(
							x: orientational(vertical: leadingColumnOffset, horizontal: currentRowOffset),
							y: orientational(vertical: currentRowOffset, horizontal: leadingColumnOffset),
							width: orientational(vertical: collectionView.frame.width - contentInsets.horizontal, horizontal: row.rowLength),
							height: orientational(vertical: row.rowLength, horizontal: collectionView.frame.height - contentInsets.vertical)
						)
						$0.zIndex = Self.rowBackgroundZIndex
					}
				}

				currentRowOffset += row.rowLength
			}

			if backgrounds.column == .enabled && Set(section.rows.map(\.maxColumnCount)).count == 1 && Set(section.rows.map(\.columnSpacings)).count == 1 {
				switch orientation {
				case .vertical(_, lastColumnAlignment: .left, _), .vertical(_, lastColumnAlignment: .right, _), .horizontal(_, lastColumnAlignment: .top, _), .horizontal(_, lastColumnAlignment: .bottom, _):
					let columnCount = section.rows[0].maxColumnCount
					var currentColumnOffset = leadingColumnOffset
					for columnIndex in 0 ..< columnCount {
						if columnIndex > 0 {
							currentColumnOffset += section.rows[0].columnSpacings[columnIndex - 1]
						}
						columnBackgroundAttributes[.init(section: sectionIndex, column: columnIndex)] = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.columnBackgroundElementKind, with: .init(item: columnIndex, section: sectionIndex)).with {
							$0.frame = .init(
								x: orientational(vertical: currentColumnOffset, horizontal: sectionRowOffset),
								y: orientational(vertical: sectionRowOffset, horizontal: currentColumnOffset),
								width: orientational(vertical: section.rows[0].columnLength, horizontal: currentRowOffset - sectionRowOffset),
								height: orientational(vertical: currentRowOffset - sectionRowOffset, horizontal: section.rows[0].columnLength)
							)
							$0.zIndex = Self.columnBackgroundZIndex
						}
						currentColumnOffset += section.rows[0].columnLength
					}
				case .vertical(_, lastColumnAlignment: .center, _), .horizontal(_, lastColumnAlignment: .center, _), .vertical(_, lastColumnAlignment: .fillEqually, _), .horizontal(_, lastColumnAlignment: .fillEqually, _):
					// cannot create column backgrounds for potentially uneven columns, ignoring
					break
				}
			}

			if backgrounds.section == .enabled {
				sectionBackgroundAttributes.append(UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.sectionBackgroundElementKind, with: .init(item: 0, section: sectionIndex)).with {
					$0.frame = .init(
						x: orientational(vertical: leadingColumnOffset, horizontal: sectionRowOffset),
						y: orientational(vertical: sectionRowOffset, horizontal: leadingColumnOffset),
						width: orientational(vertical: collectionView.frame.width - contentInsets.horizontal, horizontal: currentRowOffset - sectionRowOffset),
						height: orientational(vertical: currentRowOffset - sectionRowOffset, horizontal: collectionView.frame.height - contentInsets.vertical)
					)
					$0.zIndex = Self.sectionBackgroundZIndex
				})
			}
		}

		let trailingRowOffset = orientational(contentInsets, vertical: \.bottom, horizontal: \.right)
		calculatedContentLength = currentRowOffset + trailingRowOffset

		if backgrounds.content == .enabled {
			contentBackgroundAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.contentBackgroundElementKind, with: .init(item: 0, section: 0)).with {
				$0.frame = .init(origin: .zero, size: collectionViewContentSize)
				$0.zIndex = Self.contentBackgroundZIndex
			}
		}
		if backgrounds.insetContent == .enabled {
			let contentSize = collectionViewContentSize
			insetContentBackgroundAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.insetContentBackgroundElementKind, with: .init(item: 0, section: 0)).with {
				$0.frame = .init(
					x: contentInsets.left,
					y: contentInsets.top,
					width: contentSize.width - contentInsets.horizontal,
					height: contentSize.height - contentInsets.vertical
				)
				$0.zIndex = Self.insetContentBackgroundZIndex
			}
		}
	}

	// swiftlint:disable:next cyclomatic_complexity
	private func calculateLayout() -> CalculatedLayout {
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }

		let availableColumnLength = self.availableColumnLength()
		let calculatedRowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: columnConstraint)

		var calculatedSections = [CalculatedLayout.Section]()
		var calculatedSectionSpacings = [CGFloat]()

		let isFillingRowEqually: Bool
		let maxItemsToRedistributePerRow: Int
		switch orientation {
		case let .vertical(_, lastColumnAlignment: .fillEqually(orientationMaxItemsToRedistributePerRow), _), let .horizontal(_, lastColumnAlignment: .fillEqually(orientationMaxItemsToRedistributePerRow), _):
			isFillingRowEqually = true
			maxItemsToRedistributePerRow = orientationMaxItemsToRedistributePerRow
		case .vertical, .horizontal:
			isFillingRowEqually = false
			maxItemsToRedistributePerRow = 0
		}

		for sectionIndex in 0 ..< collectionView.numberOfSections {
			if sectionIndex > 0 {
				calculatedSectionSpacings.append(delegate?.sectionSpacing(between: sectionIndex - 1, and: sectionIndex, in: self, in: collectionView) ?? sectionSpacing)
			}

			var calculatedRows = [CalculatedLayout.Row]()
			var calculatedRowSpacings = [CGFloat]()

			let numberOfItems = collectionView.numberOfItems(inSection: sectionIndex)
			var rowIndex = 0
			var itemIndex = 0
			var baseRowAttributesList = [RowAttributes]()
			var rowItemIndexPaths = [[IndexPath?]]()

			while itemIndex < numberOfItems {
				let baseRowAttributes: RowAttributes
				if let columnConstraint = delegate?.columnConstraint(forRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView), columnConstraint != self.columnConstraint {
					baseRowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: columnConstraint)
				} else {
					baseRowAttributes = calculatedRowAttributes
				}
				let itemCountInRow = min(numberOfItems - itemIndex, baseRowAttributes.columnCount)

				if rowIndex > 0 {
					calculatedRowSpacings.append(delegate?.rowSpacing(between: rowIndex - 1, and: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? rowSpacing)
				}

				let rowAttributes: RowAttributes
				let itemSlotCountInRow: Int
				switch orientation {
				case .vertical(_, lastColumnAlignment: .left, _), .horizontal(_, lastColumnAlignment: .top, _), .vertical(_, lastColumnAlignment: .center, _), .horizontal(_, lastColumnAlignment: .center, _), .vertical(_, lastColumnAlignment: .right, _), .horizontal(_, lastColumnAlignment: .bottom, _):
					itemSlotCountInRow = baseRowAttributes.columnCount
					rowAttributes = baseRowAttributes
				case .vertical(_, lastColumnAlignment: .fillEqually, _), .horizontal(_, lastColumnAlignment: .fillEqually, _):
					itemSlotCountInRow = itemCountInRow
					rowAttributes = (itemCountInRow != baseRowAttributes.columnCount ? calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: .count(itemSlotCountInRow)) : baseRowAttributes)
				}

				var itemIndexPaths: [IndexPath?] = (0 ..< itemCountInRow).map { IndexPath(item: itemIndex + $0, section: sectionIndex) }
				itemIndexPaths.append(contentsOf: Array(repeating: nil, count: rowAttributes.columnCount - itemIndexPaths.count))
				rowItemIndexPaths.append(itemIndexPaths)
				baseRowAttributesList.append(baseRowAttributes)
				rowIndex += 1
				itemIndex += itemCountInRow
			}

			if isFillingRowEqually, rowItemIndexPaths.count >= 2, maxItemsToRedistributePerRow > 0, let maxColumnCount = baseRowAttributesList.last?.columnCount, var currentColumnCount = rowItemIndexPaths.last?.count, currentColumnCount < maxColumnCount - 1 {
				// redistribute items
				var redistributedCounts = rowItemIndexPaths.map { _ in 0 }
				while true {
					var modified = false
					for sourceRowIndex in (0 ... rowItemIndexPaths.count - 2).reversed() where redistributedCounts[sourceRowIndex] < maxItemsToRedistributePerRow && baseRowAttributesList[sourceRowIndex].columnCount - rowItemIndexPaths[sourceRowIndex].count < maxColumnCount - currentColumnCount && rowItemIndexPaths[sourceRowIndex].count > currentColumnCount + 1 {
						for targetRowIndex in sourceRowIndex + 1 ..< rowItemIndexPaths.count {
							let indexPath = rowItemIndexPaths[targetRowIndex - 1].removeLast()
							rowItemIndexPaths[targetRowIndex].insert(indexPath, at: 0)
						}
						redistributedCounts[sourceRowIndex] += 1
						currentColumnCount += 1
						if currentColumnCount >= maxColumnCount - 1 { break }
						modified = true
					}
					if !modified { break }
				}
			}

			itemIndex = 0
			for rowIndex in 0 ..< rowItemIndexPaths.count {
				let baseRowAttributes = baseRowAttributesList[rowIndex]
				var itemIndexPaths = rowItemIndexPaths[rowIndex]
				let itemSlotCountInRow = itemIndexPaths.count
				let itemCountInRow = itemIndexPaths.count { $0 != nil }
				switch orientation {
				case .vertical(fillDirection: .leftToRight, _, _), .horizontal(fillDirection: .topToBottom, _, _):
					break
				case .vertical(fillDirection: .rightToLeft, _, _), .horizontal(fillDirection: .bottomToTop, _, _):
					itemIndexPaths = itemIndexPaths.reversed()
				}

				let columnSpacings = (1 ..< itemIndexPaths.count).map { columnIndex in min(delegate?.columnSpacing(between: (indexPath: itemIndexPaths[optional: columnIndex - 1].flatMap { $0 }, columnIndex: columnIndex - 1), and: (indexPath: itemIndexPaths[optional: columnIndex].flatMap { $0 }, columnIndex: columnIndex), inRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? columnSpacing, columnSpacing) }
				let columnLength = self.columnLength(forColumnCount: itemSlotCountInRow, availableColumnLength: availableColumnLength)

				let firstIndexPathIndex = itemIndexPaths.firstIndex { $0 != nil }!
				let lastIndexPathIndex = itemIndexPaths.lastIndex { $0 != nil }!
				let usedColumnSpacingSum = firstIndexPathIndex == lastIndexPathIndex ? 0 : columnSpacings[firstIndexPathIndex ..< lastIndexPathIndex].reduce(0, +)
				let totalRowLength = CGFloat(itemCountInRow) * columnLength + usedColumnSpacingSum
				let alignmentColumnOffset: CGFloat
				switch orientation {
				case .vertical(_, lastColumnAlignment: .left, _), .horizontal(_, lastColumnAlignment: .top, _):
					alignmentColumnOffset = 0
				case .vertical(_, lastColumnAlignment: .center, _), .horizontal(_, lastColumnAlignment: .center, _):
					alignmentColumnOffset = (availableColumnLength - totalRowLength) / 2
				case .vertical(_, lastColumnAlignment: .right, _), .horizontal(_, lastColumnAlignment: .bottom, _):
					alignmentColumnOffset = availableColumnLength - totalRowLength
				case .vertical(_, lastColumnAlignment: .fillEqually, _), .horizontal(_, lastColumnAlignment: .fillEqually, _):
					alignmentColumnOffset = 0
				}

				let itemRowLengths: [CGFloat] = (0 ..< itemIndexPaths.count).map { columnIndex in
					guard let indexPath = itemIndexPaths[columnIndex] else { return 0 }
					switch delegate?.itemRowLength(at: indexPath, inColumn: columnIndex, inRow: rowIndex, inSection: sectionIndex, columnLength: columnLength, in: self, in: collectionView) ?? itemRowLength {
					case let .fixed(fixedItemRowLength):
						return fixedItemRowLength
					case let .ratio(ratio):
						return columnLength * ratio
					}
				}
				let maxItemRowLength = itemRowLengths.max()!

				var calculatedCells = [CalculatedLayout.Cell]()

				for columnIndex in 0 ..< itemIndexPaths.count {
					let itemRowLength: CGFloat
					let itemRowOffset: CGFloat
					switch orientation {
					case .vertical(_, _, itemDistribution: .top), .horizontal(_, _, itemDistribution: .left):
						itemRowLength = itemRowLengths[columnIndex]
						itemRowOffset = 0
					case .vertical(_, _, itemDistribution: .center), .horizontal(_, _, itemDistribution: .center):
						itemRowLength = itemRowLengths[columnIndex]
						itemRowOffset = (maxItemRowLength - itemRowLength) / 2
					case .vertical(_, _, itemDistribution: .bottom), .horizontal(_, _, itemDistribution: .right):
						itemRowLength = itemRowLengths[columnIndex]
						itemRowOffset = maxItemRowLength - itemRowLength
					case .vertical(_, _, itemDistribution: .fill), .horizontal(_, _, itemDistribution: .fill):
						itemRowLength = maxItemRowLength
						itemRowOffset = 0
					}

					calculatedCells.append(
						.init(
							columnIndex: columnIndex,
							indexPath: itemIndexPaths[columnIndex],
							rowLength: itemRowLength,
							rowOffset: itemRowOffset
						)
					)
					itemIndex += 1
				}

				calculatedRows.append(
					.init(
						index: rowIndex,
						rowLength: maxItemRowLength,
						maxColumnCount: baseRowAttributes.columnCount,
						isFillingEqually: isFillingRowEqually,
						columnLength: columnLength,
						cells: calculatedCells,
						columnSpacings: columnSpacings,
						columnOffset: alignmentColumnOffset
					)
				)
			}

			calculatedSections.append(
				.init(
					index: sectionIndex,
					rows: calculatedRows,
					rowSpacings: calculatedRowSpacings
				)
			)
		}

		return .init(
			sections: calculatedSections,
			sectionSpacings: calculatedSectionSpacings,
			rowLength: availableColumnLength,
			defaultColumnCount: calculatedRowAttributes.columnCount,
			defaultColumnLength: calculatedRowAttributes.columnLength
		)
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		recalculateLayoutIfNeeded(prepare: true)
		return allAttributes.filter { $0.frame.intersects(rect) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributes[indexPath]
	}

	public static func supplementaryView(for kind: String, indexPath: IndexPath) -> SupplementaryView? {
		switch kind {
		case contentBackgroundElementKind:
			return .contentBackground
		case insetContentBackgroundElementKind:
			return .insetContentBackground
		case sectionBackgroundElementKind:
			return .sectionBackground(index: indexPath.section)
		case rowBackgroundElementKind:
			return .rowBackground(sectionIndex: indexPath.section, rowIndex: indexPath.item)
		case columnBackgroundElementKind:
			return .columnBackground(sectionIndex: indexPath.section, columnIndex: indexPath.item)
		case itemBackgroundElementKind:
			return .itemBackground(indexPath: indexPath)
		default:
			return nil
		}
	}

	public func addObserver(_ observer: FlexColumnCollectionViewLayoutObserver) {
		observers.insert(observer)
	}

	public func removeObserver(_ observer: FlexColumnCollectionViewLayoutObserver) {
		observers.remove(observer)
	}

	public func itemCountToCompletelyFill(additionalRowCount: Int, existingItemCount: Int, inSection sectionIndex: Int) -> Int {
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
		var rowColumnCounts = [Int]()
		var currentItemCount = 0
		let availableColumnLength = self.availableColumnLength()

		func addRow() {
			let columnConstraint = delegate?.columnConstraint(forRow: rowColumnCounts.count, inSection: sectionIndex, in: self, in: collectionView) ?? self.columnConstraint
			let columnCount: Int
			switch columnConstraint {
			case let .count(count):
				columnCount = count
			case let .minLength(minColumnLength):
				columnCount = self.columnCount(forColumnLength: minColumnLength, availableColumnLength: availableColumnLength)
			}
			rowColumnCounts.append(columnCount)
			currentItemCount += columnCount
		}

		while currentItemCount < existingItemCount {
			addRow()
		}
		for _ in 0 ..< additionalRowCount {
			addRow()
		}
		return currentItemCount
	}
}
#endif
