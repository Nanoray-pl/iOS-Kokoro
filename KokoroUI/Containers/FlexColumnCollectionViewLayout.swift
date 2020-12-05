//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol FlexColumnCollectionViewLayoutDelegate: UICollectionViewDelegate {
	func lengthForItemInFlexColumnCollectionViewLayout(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGFloat
}

public class FlexColumnCollectionViewLayout: UICollectionViewLayout {
	public enum ColumnConstraint: Equatable {
		case count(_ count: Int)
		case minWidth(_ minWidth: CGFloat)
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

	public struct SizeAttributes: Hashable {
		public let columnCount: Int
		public let columnWidth: CGFloat
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

	public var columnConstraint = ColumnConstraint.minWidth(150) {
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

	public var itemLength: CGFloat = 60 {
		didSet {
			if oldValue == itemLength || delegate != nil { return }
			invalidateLayout()
		}
	}

	public var sizeAttributes: SizeAttributes {
		if let sizeAttributes = calculatedSizeAttributes {
			return sizeAttributes
		} else {
			let sizeAttributes = calculateSizeAttributes(forAvailableWidth: availableWidth())
			calculatedSizeAttributes = sizeAttributes
			return sizeAttributes
		}
	}

	private var calculatedSizeAttributes: SizeAttributes?
	private var calculatedContentLength: CGFloat = 0
	private var attributes = [UICollectionViewLayoutAttributes]()

	private var delegate: FlexColumnCollectionViewLayoutDelegate? {
		return collectionView?.delegate as? FlexColumnCollectionViewLayoutDelegate
	}

	public override var collectionViewContentSize: CGSize {
		switch orientation {
		case .vertical:
			return .init(width: collectionView?.bounds.width ?? 0, height: calculatedContentLength)
		case .horizontal:
			return .init(width: calculatedContentLength, height: collectionView?.bounds.height ?? 0)
		}
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

	private func availableWidth() -> CGFloat {
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }
		return orientational(collectionView.bounds, vertical: \.width, horizontal: \.height) - orientational(contentInsets, vertical: \.horizontal, horizontal: \.vertical)
	}

	private func calculateSizeAttributes(forAvailableWidth availableWidth: CGFloat) -> SizeAttributes {
		switch columnConstraint {
		case let .count(columnCount):
			let columnWidth = self.columnWidth(forColumnCount: columnCount, forAvailableWidth: availableWidth)
			return .init(columnCount: columnCount, columnWidth: columnWidth)
		case let .minWidth(minColumnWidth):
			let columnCount = self.columnCount(forColumnWidth: minColumnWidth, forAvailableWidth: availableWidth)
			let columnWidth = self.columnWidth(forColumnCount: columnCount, forAvailableWidth: availableWidth)
			return .init(columnCount: columnCount, columnWidth: columnWidth)
		}
	}

	private func columnWidth(forColumnCount columnCount: Int, forAvailableWidth availableWidth: CGFloat) -> CGFloat {
		return (availableWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount)
	}

	private func columnCount(forColumnWidth columnWidth: CGFloat, forAvailableWidth availableWidth: CGFloat) -> Int {
		return Int((availableWidth + columnSpacing) / columnWidth)
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let collectionView = collectionView else { return true }
		return collectionView.frame.size != newBounds.size
	}

	public override func invalidateLayout() {
		super.invalidateLayout()
		calculatedSizeAttributes = nil
	}

	public override func prepare() {
		super.prepare()
		attributes.removeAll()
		guard let collectionView = collectionView else { fatalError("FlexColumnCollectionViewLayout cannot be used without a collectionView set") }

		let availableWidth = self.availableWidth()
		calculatedSizeAttributes = calculateSizeAttributes(forAvailableWidth: availableWidth)

		let leadingColumnOffset = orientational(contentInsets, vertical: \.left, horizontal: \.top)
		let leadingRowOffset = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		var currentRowOffset: CGFloat = 0

		for sectionIndex in 0 ..< collectionView.numberOfSections {
			if sectionIndex > 0 {
				currentRowOffset += sectionSpacing
			}

			let numberOfItems = collectionView.numberOfItems(inSection: sectionIndex)
			let rowCount = Int(ceil(Double(numberOfItems) / Double(sizeAttributes.columnCount)))

			for rowIndex in 0 ..< rowCount {
				if rowIndex > 0 {
					currentRowOffset += rowSpacing
				}

				let itemCountInRow: Int
				if rowIndex < rowCount - 1 {
					itemCountInRow = sizeAttributes.columnCount
				} else {
					let modulo = numberOfItems % sizeAttributes.columnCount
					itemCountInRow = (modulo == 0 ? sizeAttributes.columnCount : modulo)
				}
				let columnWidth: CGFloat
				let alignmentColumnOffset: CGFloat
				switch orientation {
				case .vertical(_, lastColumnAlignment: .left, _), .horizontal(_, lastColumnAlignment: .top, _):
					columnWidth = sizeAttributes.columnWidth
					alignmentColumnOffset = 0
				case .vertical(_, lastColumnAlignment: .center, _), .horizontal(_, lastColumnAlignment: .center, _):
					columnWidth = sizeAttributes.columnWidth
					alignmentColumnOffset = (availableWidth - (CGFloat(itemCountInRow) * columnWidth + CGFloat(itemCountInRow - 1) * columnSpacing)) / 2
				case .vertical(_, lastColumnAlignment: .right, _), .horizontal(_, lastColumnAlignment: .bottom, _):
					columnWidth = sizeAttributes.columnWidth
					alignmentColumnOffset = availableWidth - (CGFloat(itemCountInRow) * columnWidth + CGFloat(itemCountInRow - 1) * columnSpacing)
				case .vertical(_, lastColumnAlignment: .fillEqually, _), .horizontal(_, lastColumnAlignment: .fillEqually, _):
					columnWidth = (availableWidth - CGFloat(itemCountInRow - 1) * columnSpacing) / CGFloat(itemCountInRow)
					alignmentColumnOffset = 0
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

				let itemLengths: [(indexPath: IndexPath, length: CGFloat)] = (0 ..< itemCountInRow).map { columnIndex in
					let indexPath = IndexPath(item: startingColumnIndex + columnIndex * columnIndexDirection + rowIndex * sizeAttributes.columnCount, section: sectionIndex)
					let itemLength = delegate?.lengthForItemInFlexColumnCollectionViewLayout(at: indexPath, in: collectionView) ?? self.itemLength
					return (indexPath: indexPath, length: itemLength)
				}
				let maxItemLength = itemLengths.map(\.length).max()!

				for columnIndex in 0 ..< itemCountInRow {
					let itemLength: CGFloat
					let itemOffset: CGFloat
					switch orientation {
					case .vertical(_, _, itemDistribution: .top), .horizontal(_, _, itemDistribution: .left):
						itemLength = itemLengths[columnIndex].length
						itemOffset = 0
					case .vertical(_, _, itemDistribution: .center), .horizontal(_, _, itemDistribution: .center):
						itemLength = itemLengths[columnIndex].length
						itemOffset = (maxItemLength - itemLength) / 2
					case .vertical(_, _, itemDistribution: .bottom), .horizontal(_, _, itemDistribution: .right):
						itemLength = itemLengths[columnIndex].length
						itemOffset = maxItemLength - itemLength
					case .vertical(_, _, itemDistribution: .fill), .horizontal(_, _, itemDistribution: .fill):
						itemLength = maxItemLength
						itemOffset = 0
					}

					let attribute = UICollectionViewLayoutAttributes(forCellWith: itemLengths[columnIndex].indexPath)
					switch orientation {
					case .vertical:
						attribute.frame = .init(
							x: leadingColumnOffset + alignmentColumnOffset + CGFloat(columnIndex) * (columnWidth + columnSpacing),
							y: leadingRowOffset + currentRowOffset + itemOffset,
							width: columnWidth,
							height: itemLength
						)
					case .horizontal:
						attribute.frame = .init(
							x: leadingRowOffset + currentRowOffset + itemOffset,
							y: leadingColumnOffset + alignmentColumnOffset + CGFloat(columnIndex) * (columnWidth + columnSpacing),
							width: itemLength,
							height: columnWidth
						)
					}
					attributes.append(attribute)
				}

				currentRowOffset += maxItemLength
			}
		}

		let trailingRowOffset = orientational(contentInsets, vertical: \.bottom, horizontal: \.right)
		calculatedContentLength = leadingRowOffset + currentRowOffset + trailingRowOffset
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		return attributes.filter { $0.frame.intersects(rect) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributes[indexPath.item]
	}
}
#endif
