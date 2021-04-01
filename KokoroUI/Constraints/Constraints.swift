//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public protocol Constrainable: class {
	var window: UIWindow? { get }
	var frame: CGRect { get }
	var constrainableView: UIView { get }
	var constrainableParent: Constrainable? { get }

	var leadingAnchor: NSLayoutXAxisAnchor { get }
	var trailingAnchor: NSLayoutXAxisAnchor { get }
	var leftAnchor: NSLayoutXAxisAnchor { get }
	var rightAnchor: NSLayoutXAxisAnchor { get }
	var topAnchor: NSLayoutYAxisAnchor { get }
	var bottomAnchor: NSLayoutYAxisAnchor { get }
	var widthAnchor: NSLayoutDimension { get }
	var heightAnchor: NSLayoutDimension { get }
	var centerXAnchor: NSLayoutXAxisAnchor { get }
	var centerYAnchor: NSLayoutYAxisAnchor { get }

	func prepareForConstraintBasedLayout()
}

public extension Constrainable {
	var isRightToLeft: Bool {
		return UIView.userInterfaceLayoutDirection(for: constrainableView.semanticContentAttribute) == .rightToLeft
	}
}

extension UIView: Constrainable {
	public var constrainableView: UIView {
		return self
	}

	public var constrainableParent: Constrainable? {
		return superview
	}

	public func prepareForConstraintBasedLayout() {
		translatesAutoresizingMaskIntoConstraints = false
	}
}

extension UILayoutGuide: Constrainable {
	public var window: UIWindow? {
		return owningView?.window
	}

	public var frame: CGRect {
		let frame = owningView!.frame
		let insets = owningView!.safeAreaInsets
		return CGRect(x: frame.origin.x + insets.left, y: frame.origin.y + insets.top, width: frame.width - insets.horizontal, height: frame.height - insets.vertical)
	}

	public var constrainableView: UIView {
		return owningView!
	}

	public var constrainableParent: Constrainable? {
		return owningView
	}

	public func prepareForConstraintBasedLayout() {
		owningView!.prepareForConstraintBasedLayout()
	}
}

public protocol Constraint: class, Constraints {
	var isActive: Bool { get }
	var priority: UILayoutPriority { get set }

	func activate()
	func deactivate()
}

public extension Constraint {
	@discardableResult
	func priority(_ priority: UILayoutPriority) -> Self {
		self.priority = priority
		return self
	}
}

public protocol Constraints {
	func flatMap() -> [Constraint]
	func flatMapBasicConstraints() -> [NSLayoutConstraint]
	func flatMapNonBasicConstraints() -> [NonBasicConstraint]
}

public extension Constraints {
	func activate() {
		KokoroUI.activate(self)
	}

	func deactivate() {
		KokoroUI.deactivate(self)
	}

	func priority(_ priority: UILayoutPriority) -> Self {
		flatMap().forEach { $0.priority = priority }
		return self
	}
}

extension NSLayoutConstraint: Constraint {
	public func flatMap() -> [Constraint] {
		return [self]
	}

	public func flatMapBasicConstraints() -> [NSLayoutConstraint] {
		return [self]
	}

	public func flatMapNonBasicConstraints() -> [NonBasicConstraint] {
		return []
	}
}

public extension Constraint {
	func flatMap() -> [Constraint] {
		return [self]
	}

	func flatMapBasicConstraints() -> [NSLayoutConstraint] {
		return flatMap().ofType(NSLayoutConstraint.self)
	}

	func flatMapNonBasicConstraints() -> [NonBasicConstraint] {
		return flatMap().ofType(NonBasicConstraint.self)
	}
}

extension Array: Constraints where Element: Constraint {
	public func flatMap() -> [Constraint] {
		return self
	}

	public func flatMapBasicConstraints() -> [NSLayoutConstraint] {
		return ofType(NSLayoutConstraint.self)
	}

	public func flatMapNonBasicConstraints() -> [NonBasicConstraint] {
		return ofType(NonBasicConstraint.self)
	}

	public static func += (left: inout Self, right: Constraints) {
		left.append(contentsOf: right.flatMap().ofType(Element.self))
	}
}

public func activate(_ constraints: [Constraints]) {
	NSLayoutConstraint.activate(constraints.flatMap { $0.flatMapBasicConstraints() }.filter { !$0.isActive })
	constraints.flatMap { $0.flatMapNonBasicConstraints() }.forEach { $0.activate() }
}

public func activate(_ constraints: Constraints...) {
	activate(constraints)
}

public func deactivate(_ constraints: [Constraints]) {
	NSLayoutConstraint.deactivate(constraints.flatMap { $0.flatMapBasicConstraints() }.filter { $0.isActive })
	constraints.flatMap { $0.flatMapNonBasicConstraints() }.forEach { $0.deactivate() }
}

public func deactivate(_ constraints: Constraints...) {
	deactivate(constraints)
}

public struct ConstraintSet: Constraints {
	public var constraints = [Constraint]()

	public static func += (left: inout Self, right: [Constraints]) {
		left.constraints.append(contentsOf: right.flatMap { $0.flatMap() })
	}

	public static func += (left: inout Self, right: Constraints) {
		left.constraints.append(contentsOf: right.flatMap())
	}

	public func flatMap() -> [Constraint] {
		return constraints
	}

	public func flatMapBasicConstraints() -> [NSLayoutConstraint] {
		return constraints.ofType(NSLayoutConstraint.self)
	}

	public func flatMapNonBasicConstraints() -> [NonBasicConstraint] {
		return constraints.ofType(NonBasicConstraint.self)
	}
}

extension ConstraintSet: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Constraints...) {
		self.constraints = elements.flatMap { $0.flatMap() }
	}
}
#endif
