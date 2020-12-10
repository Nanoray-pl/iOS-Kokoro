//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol FlexColumnCollectionViewLayoutDelegate: UICollectionViewDelegate {
	/// - Warning: This method can also be called for indexes outside of your data source's bounds when additional layout calculations are requested (for example, when calling `FlexColumnCollectionViewLayout.itemCountToCompletelyFill(rowCount:inSection:)`).
	func columnConstraint(forRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ColumnConstraint

	func itemRowLength(at indexPath: IndexPath?, inColumn columnIndex: Int, inRow rowIndex: Int, inSection sectionIndex: Int, columnLength: CGFloat, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ItemRowLength
	func sectionSpacing(between precedingSectionIndex: Int, and followingSectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
	func rowSpacing(between precedingRowIndex: Int, and followingRowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
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
	private struct WeakObserver {
		weak var wrapped: FlexColumnCollectionViewLayoutObserver?

		init(wrapping wrapped: FlexColumnCollectionViewLayoutObserver) {
			self.wrapped = wrapped
		}
	}

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
			public enum Vertical {
				case left, center, right, fillEqually
			}

			public enum Horizontal {
				case top, center, bottom, fillEqually
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

	private var calculatedLayoutStorage: CalculatedLayout? {
		didSet {
			if oldValue == calculatedLayoutStorage { return }
			guard let layout = calculatedLayoutStorage, let collectionView = collectionView else { return }
			observers.forEach { $0.wrapped?.didRecalculateLayout(to: layout, in: self, in: collectionView) }
		}
	}

	private var observers = [WeakObserver]() {
		didSet {
			guard observers.contains(where: { $0.wrapped == nil }) else { return }
			observers = observers.filter { $0.wrapped != nil }
		}
	}

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

	public func availableColumnLength() -> CGFloat {
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
		return Int((availableColumnLength + columnSpacing) / columnLength)
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let collectionView = collectionView else { return true }
		return collectionView.frame.size != newBounds.size
	}

	public override func invalidateLayout() {
		super.invalidateLayout()
		isLayoutInvalidated = true
	}

	public override func prepare() {
		super.prepare()
		if calculatedLayoutStorage == nil || isLayoutInvalidated {
			calculatedLayoutStorage = calculateLayout()
			isLayoutInvalidated = false
		}
		attributes.removeAll()

		let layout = calculatedLayout
		let leadingColumnOffset = orientational(contentInsets, vertical: \.left, horizontal: \.top)
		let leadingRowOffset = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		var currentRowOffset: CGFloat = 0

		for sectionIndex in 0 ..< layout.sections.count {
			if sectionIndex > 0 {
				currentRowOffset += layout.sectionSpacings[sectionIndex - 1]
			}
			let section = layout.sections[sectionIndex]

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
						let frameRowOffset = leadingRowOffset + currentRowOffset + cell.rowOffset
						let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
						attribute.frame = .init(
							x: orientational(vertical: frameColumnOffset, horizontal: frameRowOffset),
							y: orientational(vertical: frameRowOffset, horizontal: frameColumnOffset),
							width: orientational(vertical: row.columnLength, horizontal: cell.rowLength),
							height: orientational(vertical: cell.rowLength, horizontal: row.columnLength)
						)
						attributes[indexPath] = attribute
					}
					currentColumnOffset += row.columnLength
				}
				currentRowOffset += row.rowLength
			}
		}

		let trailingRowOffset = orientational(contentInsets, vertical: \.bottom, horizontal: \.right)
		calculatedContentLength = leadingRowOffset + currentRowOffset + trailingRowOffset
	}

	private func calculateLayout() -> CalculatedLayout {
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }

		let availableColumnLength = self.availableColumnLength()
		let calculatedRowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: columnConstraint)

		var calculatedSections = [CalculatedLayout.Section]()
		var calculatedSectionSpacings = [CGFloat]()

		for sectionIndex in 0 ..< collectionView.numberOfSections {
			if sectionIndex > 0 {
				calculatedSectionSpacings.append(delegate?.sectionSpacing(between: sectionIndex - 1, and: sectionIndex, in: self, in: collectionView) ?? sectionSpacing)
			}

			var calculatedRows = [CalculatedLayout.Row]()
			var calculatedRowSpacings = [CGFloat]()

			let numberOfItems = collectionView.numberOfItems(inSection: sectionIndex)
			var rowIndex = 0
			var itemIndex = 0

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
				let isFillingRowEqually: Bool
				switch orientation {
				case .vertical(_, lastColumnAlignment: .left, _), .horizontal(_, lastColumnAlignment: .top, _), .vertical(_, lastColumnAlignment: .center, _), .horizontal(_, lastColumnAlignment: .center, _), .vertical(_, lastColumnAlignment: .right, _), .horizontal(_, lastColumnAlignment: .bottom, _):
					isFillingRowEqually = false
					itemSlotCountInRow = baseRowAttributes.columnCount
					rowAttributes = baseRowAttributes
				case .vertical(_, lastColumnAlignment: .fillEqually, _), .horizontal(_, lastColumnAlignment: .fillEqually, _):
					isFillingRowEqually = true
					itemSlotCountInRow = itemCountInRow
					rowAttributes = (itemCountInRow != baseRowAttributes.columnCount ? calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: .count(itemSlotCountInRow)) : baseRowAttributes)
				}

				var itemIndexPaths: [IndexPath?] = (0 ..< itemCountInRow).map { IndexPath(item: itemIndex + $0, section: sectionIndex) }
				switch orientation {
				case .vertical(fillDirection: .leftToRight, _, _), .horizontal(fillDirection: .topToBottom, _, _):
					break
				case .vertical(fillDirection: .rightToLeft, _, _), .horizontal(fillDirection: .bottomToTop, _, _):
					itemIndexPaths = itemIndexPaths.reversed()
				}
				itemIndexPaths.append(contentsOf: Array(repeating: nil, count: rowAttributes.columnCount - itemIndexPaths.count))

				let columnSpacings = (1 ..< rowAttributes.columnCount).map { columnIndex in min(delegate?.columnSpacing(between: (indexPath: itemIndexPaths[optional: columnIndex - 1].flatMap { $0 }, columnIndex: columnIndex - 1), and: (indexPath: itemIndexPaths[optional: columnIndex].flatMap { $0 }, columnIndex: columnIndex), inRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? columnSpacing, columnSpacing) }
				let columnLength = (columnSpacings.allSatisfy { $0 == columnSpacing } ? rowAttributes.columnLength : self.columnLength(forColumnCount: itemSlotCountInRow, availableColumnLength: availableColumnLength, columnSpacings: columnSpacings))

				let totalRowLength = CGFloat(itemCountInRow) * columnLength + columnSpacings.reduce(0, +)
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
						maxColumnCount: rowAttributes.columnCount,
						isFillingEqually: isFillingRowEqually,
						columnLength: columnLength,
						cells: calculatedCells,
						columnSpacings: columnSpacings,
						columnOffset: alignmentColumnOffset
					)
				)
				rowIndex += 1
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
		return attributes.values.filter { $0.frame.intersects(rect) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributes[indexPath]
	}

	public func addObserver(_ observer: FlexColumnCollectionViewLayoutObserver) {
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver(_ observer: FlexColumnCollectionViewLayoutObserver) {
		observers.removeFirst { $0.wrapped === observer }
	}

	/// Calculates the item count that would be required to fill all columns of `rowCount` rows of a specific section.
	public func itemCountToCompletelyFill(rowCount: Int, inSection sectionIndex: Int) -> Int {
		var rowColumnCounts = [Int]()
		if !isLayoutInvalidated, let layout = calculatedLayoutStorage, let section = layout.sections[optional: sectionIndex] {
			rowColumnCounts = section.rows.map(\.maxColumnCount)
			if rowCount <= rowColumnCounts.count {
				return rowColumnCounts.reduce(0, +)
			}
		}

		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
		let availableColumnLength = self.availableColumnLength()
		for rowIndex in rowColumnCounts.count ..< rowCount {
			let columnConstraint = delegate?.columnConstraint(forRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? self.columnConstraint
			let columnCount: Int
			switch columnConstraint {
			case let .count(count):
				columnCount = count
			case let .minLength(minColumnLength):
				columnCount = self.columnCount(forColumnLength: minColumnLength, availableColumnLength: availableColumnLength)
			}
			rowColumnCounts.append(columnCount)
		}
		return rowColumnCounts.reduce(0, +)
	}
}
#endif
