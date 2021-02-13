//
//  Created on 16/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public extension UIView {
	private func identifier(file: String, function: String, line: Int) -> String {
		return "\(file.split(separator: "/").last!):\(function):\(line)"
	}

	private func unsafeSuperview() -> UIView {
		guard let superview = self.superview else { fatalError("Cannot set constraints dependent on superview - superview not set") }
		return superview
	}

	// MARK: Single Edges

	func topToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return topToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func topToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return top(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func topToBottomOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return topToBottomOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func topToBottomOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return topToBottom(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func topToCenterYOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return topToCenterYOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func topToCenterYOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return topToCenterY(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func bottomToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottomToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func bottomToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return bottom(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func bottomToTopOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottomToTopOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func bottomToTopOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return bottomToTop(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func bottomToCenterYOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottomToCenterYOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func bottomToCenterYOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return bottomToCenterY(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func leadingToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leadingToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leadingToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return leading(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func leadingToTrailingOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leadingToTrailingOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leadingToTrailingOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return leadingToTrailing(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func leadingToCenterXOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leadingToCenterXOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func leadingToCenterXOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return leadingToCenterX(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func trailingToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailingToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func trailingToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return trailing(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func trailingToLeadingOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailingToLeadingOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func trailingToLeadingOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return trailingToLeading(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func trailingToCenterXOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailingToCenterXOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func trailingToCenterXOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return trailingToCenterX(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func leftToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leftToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leftToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return left(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func leftToRightOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leftToRightOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leftToRightOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return leftToRight(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func leftToCenterXOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leftToCenterXOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func leftToCenterXOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return leftToCenterX(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func rightToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return rightToSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func rightToSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return right(to: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func rightToLeftOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return rightToLeftOfSuperview(inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func rightToLeftOfSuperview(inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return rightToLeft(of: unsafeSuperview(), inset: inset, relation: relation, identifier: identifier)
	}

	func rightToCenterXOfSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return rightToCenterXOfSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func rightToCenterXOfSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return rightToCenterX(of: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	// MARK: Multiple Edges

	func verticalEdgesToSuperview(insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return verticalEdgesToSuperview(insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func verticalEdgesToSuperview(insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return verticalEdgesToSuperview(topInset: insets, bottomInset: insets, relation: relation, identifier: identifier)
	}

	func verticalEdgesToSuperview(topInset: CGFloat, bottomInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return verticalEdgesToSuperview(topInset: topInset, bottomInset: bottomInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func verticalEdgesToSuperview(topInset: CGFloat, bottomInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			topToSuperview(inset: topInset, relation: relation.startingRelation, identifier: identifier),
			bottomToSuperview(inset: bottomInset, relation: relation.endingRelation, identifier: identifier),
		]
	}

	func horizontalEdgesToSuperview(insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdgesToSuperview(insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdgesToSuperview(insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return horizontalEdgesToSuperview(leadingInset: insets, trailingInset: insets, relation: relation, identifier: identifier)
	}

	func horizontalEdgesToSuperview(leftInset: CGFloat, rightInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdgesToSuperview(leftInset: leftInset, rightInset: rightInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdgesToSuperview(leftInset: CGFloat, rightInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			leftToSuperview(inset: leftInset, relation: relation.startingRelation, identifier: identifier),
			rightToSuperview(inset: rightInset, relation: relation.endingRelation, identifier: identifier),
		]
	}

	func horizontalEdgesToSuperview(leadingInset: CGFloat, trailingInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdgesToSuperview(leadingInset: leadingInset, trailingInset: trailingInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdgesToSuperview(leadingInset: CGFloat, trailingInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return horizontalEdges(to: unsafeSuperview(), leadingInset: leadingInset, trailingInset: trailingInset, relation: relation, identifier: identifier)
	}

	func edgesToSuperview(insets: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return edgesToSuperview(insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func edgesToSuperview(insets: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return verticalEdgesToSuperview(insets: insets, relation: relation, identifier: identifier) + horizontalEdgesToSuperview(insets: insets, relation: relation, identifier: identifier)
	}

	func edgesToSuperview(insets: EdgeInsets = UIEdgeInsets(), relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return edgesToSuperview(insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func edgesToSuperview(insets: EdgeInsets = UIEdgeInsets(), relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		let vertical = verticalEdgesToSuperview(topInset: insets.top, bottomInset: insets.bottom, relation: relation, identifier: identifier)
		switch insets.typed {
		case let .simple(insets):
			return vertical + horizontalEdgesToSuperview(leftInset: insets.left, rightInset: insets.right, relation: relation, identifier: identifier)
		case let .directional(insets):
			return vertical + horizontalEdgesToSuperview(leadingInset: insets.leading, trailingInset: insets.trailing, relation: relation, identifier: identifier)
		}
	}

	// MARK: unsafeSuperview() - Centering

	func centerInSuperview(offset: UIOffset = UIOffset(), file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return centerInSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerInSuperview(offset: UIOffset = UIOffset(), identifier: String) -> [NSLayoutConstraint] {
		return [
			centerXInSuperview(offset: offset.horizontal, identifier: identifier),
			centerYInSuperview(offset: offset.vertical, identifier: identifier),
		]
	}

	func centerXInSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerXInSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerXInSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return centerX(in: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	func centerYInSuperview(offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerYInSuperview(offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerYInSuperview(offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		return centerY(in: unsafeSuperview(), offset: offset, identifier: identifier)
	}

	// MARK: Sizing

	func sizeToSuperview(ratio: CGFloat = 1, offset: UIOffset = UIOffset(), relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return sizeToSuperview(ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func sizeToSuperview(ratio: CGFloat = 1, offset: UIOffset = UIOffset(), relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return size(to: unsafeSuperview(), ratio: ratio, offset: offset, relation: relation, identifier: identifier)
	}

	func widthToSuperview(ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return widthToSuperview(ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func widthToSuperview(ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return width(to: unsafeSuperview(), ratio: ratio, offset: offset, relation: relation, identifier: identifier)
	}

	func heightToSuperview(ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return heightToSuperview(ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func heightToSuperview(ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		return height(to: unsafeSuperview(), ratio: ratio, offset: offset, relation: relation, identifier: identifier)
	}
}
#endif
