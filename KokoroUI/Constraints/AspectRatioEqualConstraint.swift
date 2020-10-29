//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public class AspectRatioEqualConstraint: NonBasicConstraint, ObjectWith {
	public private(set) var isActive: Bool = false

	public var priority: UILayoutPriority = .required {
		didSet {
			if isActive {
				updateUnderlyingConstraint()
			}
		}
	}

	private weak var constrainable: Constrainable?
	private weak var observedConstrainable: Constrainable?

	private weak var helper: FrameObservingView?
	private weak var underlyingConstraint: NSLayoutConstraint?
	private lazy var internalDelegate = InternalDelegate(parent: self) // swiftlint:disable:this weak_delegate

	public init(constrainable: Constrainable, observedConstrainable: Constrainable) {
		self.constrainable = constrainable
		self.observedConstrainable = observedConstrainable
	}

	deinit {
		helper?.removeFromSuperview()
		underlyingConstraint?.deactivate()
	}

	public func activate() {
		guard !isActive, let observedConstrainable = observedConstrainable else { return }
		isActive = true
		constrainable?.addConstraint(self)

		helper = FrameObservingView().with {
			$0.delegate = internalDelegate
			observedConstrainable.constrainableView.addSubview($0)
			$0.edges(to: observedConstrainable).activate()
		}
		updateUnderlyingConstraint()
	}

	public func deactivate() {
		guard isActive else { return }
		isActive = false
		constrainable?.removeConstraint(self)
		underlyingConstraint?.deactivate()
		helper?.removeFromSuperview()
	}

	private func updateUnderlyingConstraint() {
		underlyingConstraint?.deactivate()
		guard let observedConstrainable = observedConstrainable, let constrainable = constrainable else { return }

		let newConstraint: NSLayoutConstraint
		if constrainable.frame.size.min == 0 {
			newConstraint = constrainable.width(of: 0, relation: .greaterThanOrEqual)
		} else {
			newConstraint = constrainable.ratio(size: observedConstrainable.frame.size)
		}
		newConstraint.priority = priority
		newConstraint.activate()
	}

	private class InternalDelegate: FrameObservingViewDelegate {
		private unowned let parent: AspectRatioEqualConstraint

		init(parent: AspectRatioEqualConstraint) {
			self.parent = parent
		}

		func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView) {
			guard oldFrame.size != newFrame.size else { return }
			parent.updateUnderlyingConstraint()
		}
	}
}

public extension Constrainable {
	func aspectRatio(to observedConstrainable: Constrainable) -> AspectRatioEqualConstraint {
		return AspectRatioEqualConstraint(constrainable: self, observedConstrainable: observedConstrainable)
	}
}
#endif
