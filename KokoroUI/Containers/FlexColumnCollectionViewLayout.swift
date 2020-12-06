//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol FlexColumnCollectionViewLayoutDelegate: UICollectionViewDelegate {
	func columnConstraint(forRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ColumnConstraint
	func itemRowLength(at indexPath: IndexPath, inColumn columnIndex: Int, inRow rowIndex: Int, rowAttributes: FlexColumnCollectionViewLayout.RowAttributes, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
	func sectionSpacing(between precedingSectionIndex: Int, and followingSectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
	func rowSpacing(between precedingRowIndex: Int, and followingRowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat

	/// - Warning: The value returned from this method cannot be smaller than `layout.columnSpacing` - if it is, `layout.columnSpacing` will be used instead.
	func columnSpacing(between preceding: (indexPath: IndexPath?, columnIndex: Int), and following: (indexPath: IndexPath?, columnIndex: Int), inRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat
}

public extension FlexColumnCollectionViewLayoutDelegate {
	func columnConstraint(forRow rowIndex: Int, inSection sectionIndex: Int, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ColumnConstraint {
		return layout.columnConstraint
	}

	func itemRowLength(at indexPath: IndexPath, inColumn columnIndex: Int, inRow rowIndex: Int, rowAttributes: FlexColumnCollectionViewLayout.RowAttributes, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> CGFloat {
		switch layout.itemRowLength {
		case let .fixed(length):
			return length
		case let .ratio(ratio):
			return rowAttributes.columnLength * ratio
		}
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

public class FlexColumnCollectionViewLayout: UICollectionViewLayout {
	public enum ColumnConstraint: Equatable {
		case count(_ count: Int)
		case minLength(_ minLength: CGFloat)
	}

	public enum ItemRowLength: Equatable {
		case fixed(_ length: CGFloat)
		case ratio(_ ratio: CGFloat)
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

	public struct RowAttributes: Hashable {
		public let columnCount: Int
		public let columnLength: CGFloat
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
			if oldValue == itemRowLength || delegate != nil { return }
			invalidateLayout()
		}
	}

	public var rowAttributes: RowAttributes {
		if let rowAttributes = calculatedRowAttributes {
			return rowAttributes
		} else {
			let rowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength(), columnConstraint: columnConstraint)
			calculatedRowAttributes = rowAttributes
			return rowAttributes
		}
	}

	private var calculatedRowAttributes: RowAttributes?
	private var calculatedContentLength: CGFloat = 0
	private var attributes = [IndexPath: UICollectionViewLayoutAttributes]()

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
		return columnLength(forColumnCount: columnCount, availableColumnLength: availableColumnLength, columnSpacings: (1 ..< columnCount).map { _ in columnSpacing })
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
		calculatedRowAttributes = nil
	}

	public override func prepare() {
		super.prepare()
		attributes.removeAll()
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }

		let availableColumnLength = self.availableColumnLength()
		calculatedRowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: columnConstraint)

		let leadingColumnOffset = orientational(contentInsets, vertical: \.left, horizontal: \.top)
		let leadingRowOffset = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		var currentRowOffset: CGFloat = 0

		for sectionIndex in 0 ..< collectionView.numberOfSections {
			if sectionIndex > 0 {
				currentRowOffset += delegate?.sectionSpacing(between: sectionIndex - 1, and: sectionIndex, in: self, in: collectionView) ?? sectionSpacing
			}

			let numberOfItems = collectionView.numberOfItems(inSection: sectionIndex)
			var rowIndex = 0
			var itemIndex = 0

			while itemIndex < numberOfItems {
				let baseRowAttributes: RowAttributes
				if let columnConstraint = delegate?.columnConstraint(forRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView), columnConstraint != self.columnConstraint {
					baseRowAttributes = calculateRowAttributes(availableColumnLength: availableColumnLength, columnConstraint: columnConstraint)
				} else {
					baseRowAttributes = self.rowAttributes
				}
				let itemCountInRow = min(numberOfItems - itemIndex, baseRowAttributes.columnCount)

				if rowIndex > 0 {
					currentRowOffset += delegate?.rowSpacing(between: rowIndex - 1, and: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? rowSpacing
				}

				let startingColumnIndex: Int
				let columnIndexDirection: Int
				switch orientation {
				case .vertical(fillDirection: .leftToRight, _, _), .horizontal(fillDirection: .topToBottom, _, _):
					startingColumnIndex = 0
					columnIndexDirection = 1
				case .vertical(fillDirection: .rightToLeft, _, _), .horizontal(fillDirection: .bottomToTop, _, _):
					startingColumnIndex = itemCountInRow - 1
					columnIndexDirection = -1
				}

				let itemIndexPaths = (0 ..< itemCountInRow).map { columnIndex in IndexPath(item: itemIndex + startingColumnIndex + columnIndex * columnIndexDirection, section: sectionIndex) }

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
				let columnSpacings = (1 ..< itemSlotCountInRow).map { columnIndex in min(delegate?.columnSpacing(between: (indexPath: itemIndexPaths[optional: columnIndex - 1], columnIndex: columnIndex - 1), and: (indexPath: itemIndexPaths[optional: columnIndex], columnIndex: columnIndex), inRow: rowIndex, inSection: sectionIndex, in: self, in: collectionView) ?? columnSpacing, columnSpacing) }
				let columnLength = (columnSpacings.allSatisfy { $0 == columnSpacing } ? rowAttributes.columnLength : self.columnLength(forColumnCount: itemSlotCountInRow, availableColumnLength: availableColumnLength, columnSpacings: columnSpacings))

				let totalRowLength = CGFloat(itemCountInRow) * columnLength - columnSpacings.reduce(0, +)
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

				let itemRowLengths: [CGFloat] = (0 ..< itemCountInRow).map { columnIndex in
					if let itemRowLength = delegate?.itemRowLength(at: itemIndexPaths[columnIndex], inColumn: columnIndex, inRow: rowIndex, rowAttributes: rowAttributes, in: self, in: collectionView) {
						return itemRowLength
					} else {
						switch self.itemRowLength {
						case let .fixed(fixedItemRowLength):
							return fixedItemRowLength
						case let .ratio(ratio):
							return columnLength * ratio
						}
					}
				}
				let maxItemRowLength = itemRowLengths.max()!

				var currentColumnOffset: CGFloat
				switch orientation {
				case .vertical(fillDirection: .leftToRight, _, _), .horizontal(fillDirection: .topToBottom, _, _):
					currentColumnOffset = 0
				case .vertical(fillDirection: .rightToLeft, _, _), .horizontal(fillDirection: .bottomToTop, _, _):
					currentColumnOffset = totalRowLength - columnLength
				}

				for columnIndex in 0 ..< itemCountInRow {
					if columnIndex > 0 {
						currentColumnOffset += CGFloat(columnIndexDirection) * (columnLength + (columnSpacings[optional: startingColumnIndex + columnIndex * columnIndexDirection - 1] ?? 0))
					}

					let itemRowLength: CGFloat
					let itemOffset: CGFloat
					switch orientation {
					case .vertical(_, _, itemDistribution: .top), .horizontal(_, _, itemDistribution: .left):
						itemRowLength = itemRowLengths[columnIndex]
						itemOffset = 0
					case .vertical(_, _, itemDistribution: .center), .horizontal(_, _, itemDistribution: .center):
						itemRowLength = itemRowLengths[columnIndex]
						itemOffset = (maxItemRowLength - itemRowLength) / 2
					case .vertical(_, _, itemDistribution: .bottom), .horizontal(_, _, itemDistribution: .right):
						itemRowLength = itemRowLengths[columnIndex]
						itemOffset = maxItemRowLength - itemRowLength
					case .vertical(_, _, itemDistribution: .fill), .horizontal(_, _, itemDistribution: .fill):
						itemRowLength = maxItemRowLength
						itemOffset = 0
					}

					let itemIndexPath = itemIndexPaths[columnIndex]
					let attribute = UICollectionViewLayoutAttributes(forCellWith: itemIndexPath)
					let frameColumnOffset = leadingColumnOffset + alignmentColumnOffset + currentColumnOffset
					let frameRowOffset = leadingRowOffset + currentRowOffset + itemOffset
					attribute.frame = .init(
						x: orientational(vertical: frameColumnOffset, horizontal: frameRowOffset),
						y: orientational(vertical: frameRowOffset, horizontal: frameColumnOffset),
						width: orientational(vertical: columnLength, horizontal: itemRowLength),
						height: orientational(vertical: itemRowLength, horizontal: columnLength)
					)
					attributes[itemIndexPath] = attribute
					itemIndex += 1
				}

				currentRowOffset += maxItemRowLength
				rowIndex += 1
			}
		}

		let trailingRowOffset = orientational(contentInsets, vertical: \.bottom, horizontal: \.right)
		calculatedContentLength = leadingRowOffset + currentRowOffset + trailingRowOffset
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		return attributes.values.filter { $0.frame.intersects(rect) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributes[indexPath]
	}
}
#endif
