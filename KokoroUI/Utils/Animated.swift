//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public enum Animated {
	public static let defaultDuration: TimeInterval = 0.4

	case motionBased, `false`, `true`

	public var value: Bool {
		switch self {
		case .motionBased:
			return !UIAccessibility.isReduceMotionEnabled
		case .false:
			return false
		case .true:
			return true
		}
	}

	@discardableResult
	public static func run(duration: TimeInterval = Self.defaultDuration, dampingRatio: CGFloat, started: Bool = true, animations: @escaping () -> Void) -> UIViewPropertyAnimator {
		run(duration: duration, dampingRatio: dampingRatio, started: started, animations: animations, completion: nil)
	}

	@discardableResult
	public static func run(duration: TimeInterval = Self.defaultDuration, dampingRatio: CGFloat, started: Bool = true, animations: @escaping () -> Void, completion: (() -> Void)? = nil) -> UIViewPropertyAnimator {
		let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio, animations: animations)
		if let completion = completion {
			animator.addCompletion { _ in completion() }
		}
		if started {
			animator.startAnimation()
		}
		return animator
	}

	@discardableResult
	public static func run(duration: TimeInterval = Self.defaultDuration, curve: UIView.AnimationCurve = .easeInOut, started: Bool = true, animations: @escaping () -> Void) -> UIViewPropertyAnimator {
		run(duration: duration, curve: curve, started: started, animations: animations, completion: nil)
	}

	@discardableResult
	public static func run(duration: TimeInterval = Self.defaultDuration, curve: UIView.AnimationCurve = .easeInOut, started: Bool = true, animations: @escaping () -> Void, completion: (() -> Void)? = nil) -> UIViewPropertyAnimator {
		let animator = UIViewPropertyAnimator(duration: duration, curve: curve, animations: animations)
		if let completion = completion {
			animator.addCompletion { _ in completion() }
		}
		if started {
			animator.startAnimation()
		}
		return animator
	}

	@discardableResult
	public func run(duration: TimeInterval = Self.defaultDuration, dampingRatio: CGFloat, started: Bool = true, animations: @escaping () -> Void) -> UIViewPropertyAnimator? {
		return run(duration: duration, dampingRatio: dampingRatio, started: started, animations: animations, completion: nil)
	}

	@discardableResult
	public func run(duration: TimeInterval = Self.defaultDuration, dampingRatio: CGFloat, started: Bool = true, animations: @escaping () -> Void, completion: (() -> Void)? = nil) -> UIViewPropertyAnimator? {
		if value {
			return Self.run(duration: duration, dampingRatio: dampingRatio, started: started, animations: animations, completion: completion)
		} else {
			animations()
			completion?()
			return nil
		}
	}

	@discardableResult
	public func run(duration: TimeInterval = Self.defaultDuration, curve: UIView.AnimationCurve = .easeInOut, started: Bool = true, animations: @escaping () -> Void) -> UIViewPropertyAnimator? {
		return run(duration: duration, curve: curve, started: started, animations: animations, completion: nil)
	}

	@discardableResult
	public func run(duration: TimeInterval = Self.defaultDuration, curve: UIView.AnimationCurve = .easeInOut, started: Bool = true, animations: @escaping () -> Void, completion: (() -> Void)? = nil) -> UIViewPropertyAnimator? {
		if value {
			return Self.run(duration: duration, curve: curve, started: started, animations: animations, completion: completion)
		} else {
			animations()
			completion?()
			return nil
		}
	}
}

extension Animated: ExpressibleByBooleanLiteral {
	public typealias BooleanLiteralType = Bool

	public init(booleanLiteral value: Bool) {
		self = (value ? .true : .false)
	}
}

public extension UINavigationController {
	func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
		pushViewController(viewController, animated: animated)
		if let completion = completion {
			if animated, let coordinator = transitionCoordinator {
				coordinator.animate(alongsideTransition: nil) { _ in completion() }
			} else {
				completion()
			}
		}
	}

	@discardableResult
	func popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
		let result = popViewController(animated: animated)
		if let completion = completion {
			if animated, let coordinator = transitionCoordinator {
				coordinator.animate(alongsideTransition: nil) { _ in completion() }
			} else {
				completion()
			}
		}
		return result
	}

	@discardableResult
	func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		let result = popToViewController(viewController, animated: animated)
		if let completion = completion {
			if animated, let coordinator = transitionCoordinator {
				coordinator.animate(alongsideTransition: nil) { _ in completion() }
			} else {
				completion()
			}
		}
		return result
	}

	@discardableResult
	func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		let result = popToRootViewController(animated: animated)
		if let completion = completion {
			if animated, let coordinator = transitionCoordinator {
				coordinator.animate(alongsideTransition: nil) { _ in completion() }
			} else {
				completion()
			}
		}
		return result
	}
}
#endif
