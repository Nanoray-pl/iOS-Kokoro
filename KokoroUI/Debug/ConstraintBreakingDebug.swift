//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

/// Provides a way of detecting broken constraints. The preferred usage is to call the `setup(closure:)` method with an empty closure, placing a breakpoint inside the closure, marking the breakpoint as "Shared" and commiting it into a repository.
public enum ConstraintBreakingDebug {
	public struct Info {
		public let view: UIView
		public let constraintToBreak: NSLayoutConstraint
		public let mutuallyExclusiveConstraints: [NSLayoutConstraint]

		public init(view: UIView, constraintToBreak: NSLayoutConstraint, mutuallyExclusiveConstraints: [NSLayoutConstraint]) {
			self.view = view
			self.constraintToBreak = constraintToBreak
			self.mutuallyExclusiveConstraints = mutuallyExclusiveConstraints
		}
	}

	private static var isSwizzled = false
	fileprivate static var closure: ((Info) -> Void)?

	public static func setup(closure: ((Info) -> Void)?) {
		Self.closure = closure
		swizzle()
	}

	private static func swizzle() {
		#if DEBUG
		if isSwizzled { return }

		let original = class_getInstanceMethod(UIView.self, NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:"))!
		let swizzled = class_getInstanceMethod(UIView.self, #selector(UIView.swizzledEngine(_:willBreakConstraint:dueToMutuallyExclusiveConstraints:)))!
		method_exchangeImplementations(original, swizzled)

		isSwizzled = true
		#endif
	}
}

private extension UIView {
	#if DEBUG
	@objc func swizzledEngine(_ engine: AnyObject, willBreakConstraint constraint: NSLayoutConstraint, dueToMutuallyExclusiveConstraints mutuallyExclusiveConstraints: [NSLayoutConstraint]) {
		// apparently Apple uses this flag to disable logging of any breaking constraints, and they use this flag for all of their alerts created with UIAlertController (which all have broken constraints) - ignoring if it's set
		if (value(forKey: "_isUnsatisfiableConstraintsLoggingSuspended") as? Bool) == true {
			swizzledEngine(engine, willBreakConstraint: constraint, dueToMutuallyExclusiveConstraints: mutuallyExclusiveConstraints)
			return
		}

		// ignoring the Apple action sheet constraint bug
		if mutuallyExclusiveConstraints.count == 1 && constraint.firstAttribute == .width && constraint.constant == -16 && (constraint.firstItem as? UIView)?.superview.flatMap({ String(describing: type(of: $0)) }) == "_UIAlertControllerView" {
			swizzledEngine(engine, willBreakConstraint: constraint, dueToMutuallyExclusiveConstraints: mutuallyExclusiveConstraints)
			return
		}

		ConstraintBreakingDebug.closure?(.init(view: self, constraintToBreak: constraint, mutuallyExclusiveConstraints: mutuallyExclusiveConstraints))
		swizzledEngine(engine, willBreakConstraint: constraint, dueToMutuallyExclusiveConstraints: mutuallyExclusiveConstraints)
	}
	#endif
}
#endif
