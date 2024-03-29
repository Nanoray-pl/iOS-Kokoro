//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

private extension NSLayoutDimension {
	func constraint(equalTo anchor: NSLayoutDimension, multiplier: CGFloat, identifier: String) -> NSLayoutConstraint {
		return constraint(equalTo: anchor, multiplier: multiplier).with {
			$0.identifier = identifier
		}
	}

	func constraint(equalTo anchor: NSLayoutDimension, multiplier: CGFloat, constant: CGFloat, identifier: String) -> NSLayoutConstraint {
		return constraint(equalTo: anchor, multiplier: multiplier, constant: constant).with {
			$0.identifier = identifier
		}
	}

	func constraint(constant: CGFloat, relation: NSLayoutConstraint.Relation, identifier: String) -> NSLayoutConstraint {
		let constraint: NSLayoutConstraint
		switch relation {
		case .equal:
			constraint = self.constraint(equalToConstant: constant)
		case .greaterThanOrEqual:
			constraint = self.constraint(greaterThanOrEqualToConstant: constant)
		case .lessThanOrEqual:
			constraint = self.constraint(lessThanOrEqualToConstant: constant)
		@unknown default:
			fatalError("Unknown NSLayoutConstraint.Relation \(relation)")
		}
		return constraint.with {
			$0.identifier = identifier
		}
	}

	func constraint(to anchor: NSLayoutDimension, ratio: CGFloat, constant: CGFloat, relation: NSLayoutConstraint.Relation, identifier: String) -> NSLayoutConstraint {
		let constraint: NSLayoutConstraint
		switch relation {
		case .equal:
			constraint = self.constraint(equalTo: anchor, multiplier: ratio, constant: constant)
		case .greaterThanOrEqual:
			constraint = self.constraint(greaterThanOrEqualTo: anchor, multiplier: ratio, constant: constant)
		case .lessThanOrEqual:
			constraint = self.constraint(lessThanOrEqualTo: anchor, multiplier: ratio, constant: constant)
		@unknown default:
			fatalError("Unknown NSLayoutConstraint.Relation \(relation)")
		}
		return constraint.with {
			$0.identifier = identifier
		}
	}
}

private extension NSLayoutAnchor {
	@objc func constraint(equalTo anchor: NSLayoutAnchor<AnchorType>, constant: CGFloat, identifier: String) -> NSLayoutConstraint {
		return constraint(equalTo: anchor, constant: constant).with {
			$0.identifier = identifier
		}
	}

	@objc func constraint(to anchor: NSLayoutAnchor, constant: CGFloat, relation: NSLayoutConstraint.Relation, identifier: String) -> NSLayoutConstraint {
		let constraint: NSLayoutConstraint
		switch relation {
		case .equal:
			constraint = self.constraint(equalTo: anchor, constant: constant)
		case .greaterThanOrEqual:
			constraint = self.constraint(greaterThanOrEqualTo: anchor, constant: constant)
		case .lessThanOrEqual:
			constraint = self.constraint(lessThanOrEqualTo: anchor, constant: constant)
		@unknown default:
			fatalError("Unknown NSLayoutConstraint.Relation \(relation)")
		}
		return constraint.with {
			$0.identifier = identifier
		}
	}
}

public enum MultiEdgeRelation {
	case equal, inside, outside

	var startingRelation: NSLayoutConstraint.Relation {
		switch self {
		case .equal:
			return .equal
		case .inside:
			return .greaterThanOrEqual
		case .outside:
			return .lessThanOrEqual
		}
	}

	var endingRelation: NSLayoutConstraint.Relation {
		switch self {
		case .equal:
			return .equal
		case .inside:
			return .lessThanOrEqual
		case .outside:
			return .greaterThanOrEqual
		}
	}

	func leadingRelation(isRightToLeft: Bool) -> NSLayoutConstraint.Relation {
		if isRightToLeft {
			return endingRelation
		} else {
			return startingRelation
		}
	}

	func trailingRelation(isRightToLeft: Bool) -> NSLayoutConstraint.Relation {
		if isRightToLeft {
			return startingRelation
		} else {
			return endingRelation
		}
	}
}

public extension Constrainable {
	// MARK: - Utilities

	private var rightToLeftMultiplier: CGFloat {
		return isRightToLeft ? -1 : 1
	}

	private func identifier(file: String, function: String, line: Int) -> String {
		return "\(file.split(separator: "/").last!):\(function):\(line)"
	}

	// MARK: - Single Edges

	func top(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return top(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func top(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return topAnchor.constraint(to: constrainable.topAnchor, constant: inset, relation: relation, identifier: identifier)
	}

	func topToBottom(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return topToBottom(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func topToBottom(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return topAnchor.constraint(to: constrainable.bottomAnchor, constant: inset, relation: relation, identifier: identifier)
	}

	func topToCenterY(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return topToCenterY(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func topToCenterY(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return topAnchor.constraint(equalTo: constrainable.centerYAnchor, constant: offset, identifier: identifier)
	}

	func bottom(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottom(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func bottom(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return bottomAnchor.constraint(to: constrainable.bottomAnchor, constant: -inset, relation: relation, identifier: identifier)
	}

	func bottomToTop(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottomToTop(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func bottomToTop(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return bottomAnchor.constraint(to: constrainable.topAnchor, constant: -inset, relation: relation, identifier: identifier)
	}

	func bottomToCenterY(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return bottomToCenterY(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func bottomToCenterY(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return bottomAnchor.constraint(equalTo: constrainable.centerYAnchor, constant: offset, identifier: identifier)
	}

	func leading(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leading(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leading(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leadingAnchor.constraint(to: constrainable.leadingAnchor, constant: inset * rightToLeftMultiplier, relation: relation, identifier: identifier)
	}

	func leadingToTrailing(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leadingToTrailing(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leadingToTrailing(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leadingAnchor.constraint(to: constrainable.trailingAnchor, constant: inset * rightToLeftMultiplier, relation: relation, identifier: identifier)
	}

	func leadingToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leadingToCenterX(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func leadingToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leadingAnchor.constraint(equalTo: constrainable.centerXAnchor, constant: offset, identifier: identifier)
	}

	func trailing(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailing(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func trailing(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return trailingAnchor.constraint(to: constrainable.trailingAnchor, constant: -inset * rightToLeftMultiplier, relation: relation, identifier: identifier)
	}

	func trailingToLeading(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailingToLeading(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func trailingToLeading(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return trailingAnchor.constraint(to: constrainable.leadingAnchor, constant: -inset * rightToLeftMultiplier, relation: relation, identifier: identifier)
	}

	func trailingToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return trailingToCenterX(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func trailingToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return trailingAnchor.constraint(equalTo: constrainable.centerXAnchor, constant: offset, identifier: identifier)
	}

	func left(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return left(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func left(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leftAnchor.constraint(to: constrainable.leftAnchor, constant: inset, relation: relation, identifier: identifier)
	}

	func leftToRight(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leftToRight(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func leftToRight(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leftAnchor.constraint(to: constrainable.rightAnchor, constant: inset, relation: relation, identifier: identifier)
	}

	func leftToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return leftToCenterX(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func leftToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return leftAnchor.constraint(equalTo: constrainable.centerXAnchor, constant: offset, identifier: identifier)
	}

	func right(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return right(to: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func right(to constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return rightAnchor.constraint(to: constrainable.rightAnchor, constant: -inset, relation: relation, identifier: identifier)
	}

	func rightToLeft(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return rightToLeft(of: constrainable, inset: inset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func rightToLeft(of constrainable: Constrainable, inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return rightAnchor.constraint(to: constrainable.leftAnchor, constant: -inset, relation: relation, identifier: identifier)
	}

	func rightToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return rightToCenterX(of: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func rightToCenterX(of constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return rightAnchor.constraint(equalTo: constrainable.centerXAnchor, constant: offset, identifier: identifier)
	}

	// MARK: - Multiple Edges

	func verticalEdges(to constrainable: Constrainable, insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return verticalEdges(to: constrainable, insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func verticalEdges(to constrainable: Constrainable, insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return verticalEdges(to: constrainable, topInset: insets, bottomInset: insets, relation: relation, identifier: identifier)
	}

	func verticalEdges(to constrainable: Constrainable, topInset: CGFloat, bottomInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return verticalEdges(to: constrainable, topInset: topInset, bottomInset: bottomInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func verticalEdges(to constrainable: Constrainable, topInset: CGFloat, bottomInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			top(to: constrainable, inset: topInset, relation: relation.startingRelation, identifier: identifier),
			bottom(to: constrainable, inset: bottomInset, relation: relation.endingRelation, identifier: identifier),
		]
	}

	func horizontalEdges(to constrainable: Constrainable, insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdges(to: constrainable, insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdges(to constrainable: Constrainable, insets: CGFloat = 0, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return horizontalEdges(to: constrainable, leadingInset: insets, trailingInset: insets, relation: relation, identifier: identifier)
	}

	func horizontalEdges(to constrainable: Constrainable, leftInset: CGFloat, rightInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdges(to: constrainable, leftInset: leftInset, rightInset: rightInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdges(to constrainable: Constrainable, leftInset: CGFloat, rightInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			left(to: constrainable, inset: leftInset, relation: relation.startingRelation, identifier: identifier),
			right(to: constrainable, inset: rightInset, relation: relation.endingRelation, identifier: identifier),
		]
	}

	func horizontalEdges(to constrainable: Constrainable, leadingInset: CGFloat, trailingInset: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return horizontalEdges(to: constrainable, leadingInset: leadingInset, trailingInset: trailingInset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func horizontalEdges(to constrainable: Constrainable, leadingInset: CGFloat, trailingInset: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			leading(to: constrainable, inset: leadingInset, relation: relation.leadingRelation(isRightToLeft: isRightToLeft), identifier: identifier),
			trailing(to: constrainable, inset: trailingInset, relation: relation.trailingRelation(isRightToLeft: isRightToLeft), identifier: identifier),
		]
	}

	func edges(to constrainable: Constrainable, insets: CGFloat, relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return edges(to: constrainable, insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func edges(to constrainable: Constrainable, insets: CGFloat, relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return verticalEdges(to: constrainable, topInset: insets, bottomInset: insets, relation: relation, identifier: identifier) + horizontalEdges(to: constrainable, leftInset: insets, rightInset: insets, relation: relation, identifier: identifier)
	}

	func edges(to constrainable: Constrainable, insets: EdgeInsets = UIEdgeInsets(), relation: MultiEdgeRelation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return edges(to: constrainable, insets: insets, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func edges(to constrainable: Constrainable, insets: EdgeInsets = UIEdgeInsets(), relation: MultiEdgeRelation = .equal, identifier: String) -> [NSLayoutConstraint] {
		let verticalEdges = self.verticalEdges(to: constrainable, topInset: insets.top, bottomInset: insets.bottom, relation: relation, identifier: identifier)
		switch insets.typed {
		case let .simple(insets):
			return verticalEdges + horizontalEdges(to: constrainable, leftInset: insets.left, rightInset: insets.right, relation: relation, identifier: identifier)
		case let .directional(insets):
			return verticalEdges + horizontalEdges(to: constrainable, leadingInset: insets.leading, trailingInset: insets.trailing, relation: relation, identifier: identifier)
		}
	}

	// MARK: - Centering

	func center(in constrainable: Constrainable, offset: UIOffset = UIOffset(), file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return center(in: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func center(in constrainable: Constrainable, offset: UIOffset = UIOffset(), identifier: String) -> [NSLayoutConstraint] {
		return [
			centerX(in: constrainable, offset: offset.horizontal, identifier: identifier),
			centerY(in: constrainable, offset: offset.vertical, identifier: identifier),
		]
	}

	func centerX(in constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerX(in: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerX(in constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerXAnchor.constraint(equalTo: constrainable.centerXAnchor, constant: offset, identifier: identifier)
	}

	func centerXToLeft(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerXToLeft(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerXToLeft(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerXAnchor.constraint(equalTo: constrainable.leftAnchor, constant: inset, identifier: identifier)
	}

	func centerXToLeading(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerXToLeading(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerXToLeading(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerXAnchor.constraint(equalTo: constrainable.leadingAnchor, constant: inset * rightToLeftMultiplier, identifier: identifier)
	}

	func centerXToRight(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerXToRight(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerXToRight(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerXAnchor.constraint(equalTo: constrainable.rightAnchor, constant: -inset, identifier: identifier)
	}

	func centerXToTrailing(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerXToTrailing(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerXToTrailing(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerXAnchor.constraint(equalTo: constrainable.trailingAnchor, constant: -inset * rightToLeftMultiplier, identifier: identifier)
	}

	func centerY(in constrainable: Constrainable, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerY(in: constrainable, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerY(in constrainable: Constrainable, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerYAnchor.constraint(equalTo: constrainable.centerYAnchor, constant: offset, identifier: identifier)
	}

	func centerYToTop(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerYToTop(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerYToTop(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerYAnchor.constraint(equalTo: constrainable.topAnchor, constant: inset, identifier: identifier)
	}

	func centerYToBottom(of constrainable: Constrainable, inset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return centerYToBottom(of: constrainable, inset: inset, identifier: identifier(file: file, function: function, line: line))
	}

	func centerYToBottom(of constrainable: Constrainable, inset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return centerYAnchor.constraint(equalTo: constrainable.bottomAnchor, constant: -inset, identifier: identifier)
	}

	// MARK: - Sizing

	func ratio(size: CGSize, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return ratio(size: size, identifier: identifier(file: file, function: function, line: line))
	}

	func ratio(size: CGSize, identifier: String) -> NSLayoutConstraint {
		return ratio(width: size.width, height: size.height, identifier: identifier)
	}

	func ratio(width: CGFloat = 1, height: CGFloat = 1, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return ratio(width: width, height: height, identifier: identifier(file: file, function: function, line: line))
	}

	func ratio(width: CGFloat = 1, height: CGFloat = 1, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return widthAnchor.constraint(equalTo: heightAnchor, multiplier: width / height, identifier: identifier)
	}

	func size(to constrainable: Constrainable, ratio: CGFloat = 1, offset: UIOffset = UIOffset(), relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return size(to: constrainable, ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func size(to constrainable: Constrainable, ratio: CGFloat = 1, offset: UIOffset = UIOffset(), relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> [NSLayoutConstraint] {
		return [
			width(to: constrainable, ratio: ratio, offset: offset.horizontal, relation: relation, identifier: identifier),
			height(to: constrainable, ratio: ratio, offset: offset.vertical, relation: relation, identifier: identifier),
		]
	}

	func size(of size: CGSize, file: String = #file, function: String = #function, line: Int = #line) -> [NSLayoutConstraint] {
		return self.size(of: size, identifier: identifier(file: file, function: function, line: line))
	}

	func size(of size: CGSize, identifier: String) -> [NSLayoutConstraint] {
		return [
			width(of: size.width, identifier: identifier),
			height(of: size.height, identifier: identifier),
		]
	}

	func width(to constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return width(to: constrainable, ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func width(to constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return widthAnchor.constraint(to: constrainable.widthAnchor, ratio: ratio, constant: offset, relation: relation, identifier: identifier)
	}

	func width(of points: CGFloat, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return width(of: points, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func width(of points: CGFloat, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return widthAnchor.constraint(constant: points, relation: relation, identifier: identifier)
	}

	func height(to constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return height(to: constrainable, ratio: ratio, offset: offset, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func height(to constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return heightAnchor.constraint(to: constrainable.heightAnchor, ratio: ratio, constant: offset, relation: relation, identifier: identifier)
	}

	func height(of points: CGFloat, relation: NSLayoutConstraint.Relation = .equal, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return height(of: points, relation: relation, identifier: identifier(file: file, function: function, line: line))
	}

	func height(of points: CGFloat, relation: NSLayoutConstraint.Relation = .equal, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return heightAnchor.constraint(constant: points, relation: relation, identifier: identifier)
	}

	func widthToHeight(of constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return widthToHeight(of: constrainable, ratio: ratio, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func widthToHeight(of constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return widthAnchor.constraint(equalTo: constrainable.heightAnchor, multiplier: ratio, constant: offset, identifier: identifier)
	}

	func heightToWidth(of constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, file: String = #file, function: String = #function, line: Int = #line) -> NSLayoutConstraint {
		return heightToWidth(of: constrainable, ratio: ratio, offset: offset, identifier: identifier(file: file, function: function, line: line))
	}

	func heightToWidth(of constrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0, identifier: String) -> NSLayoutConstraint {
		prepareForConstraintBasedLayout()
		return heightAnchor.constraint(equalTo: constrainable.widthAnchor, multiplier: ratio, constant: offset, identifier: identifier)
	}
}
#endif
