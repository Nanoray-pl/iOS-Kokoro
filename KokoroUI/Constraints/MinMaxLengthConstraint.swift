//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public class MinMaxLengthConstraint: NonBasicConstraint, ObjectWith {
	public enum ObservedLength {
		case min, max, average
	}

	public enum TargetLength {
		case width, height
	}

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
	private let targetLength: TargetLength
	private let observedLength: ObservedLength
	private let ratio: CGFloat
	private let offset: CGFloat

	private weak var helper: FrameObservingView?
	private weak var underlyingConstraint: NSLayoutConstraint?
	private var wasWidthGreatherThanHeight = false
	private lazy var internalDelegate = InternalDelegate(parent: self) // swiftlint:disable:this weak_delegate

	public init(constrainable: Constrainable, targetLength: TargetLength, to observedConstrainable: Constrainable, observedLength: ObservedLength, ratio: CGFloat = 1, offset: CGFloat = 0) {
		self.constrainable = constrainable
		self.observedConstrainable = observedConstrainable
		self.targetLength = targetLength
		self.observedLength = observedLength
		self.ratio = ratio
		self.offset = offset
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

		let targetAnchor: NSLayoutDimension
		switch targetLength {
		case .width:
			targetAnchor = constrainable.widthAnchor
		case .height:
			targetAnchor = constrainable.heightAnchor
		}

		let newConstraint: NSLayoutConstraint
		switch observedLength {
		case .min, .max:
			let observedAnchor: NSLayoutDimension
			switch (observedLength, observedConstrainable.frame.width <= observedConstrainable.frame.height) {
			case (.min, true), (.max, false):
				wasWidthGreatherThanHeight = false
				observedAnchor = observedConstrainable.widthAnchor
			case (.min, false), (.max, true):
				wasWidthGreatherThanHeight = true
				observedAnchor = observedConstrainable.heightAnchor
			case (.average, _):
				fatalError("Invalid state")
			}
			newConstraint = targetAnchor.constraint(equalTo: observedAnchor, multiplier: ratio, constant: offset)
		case .average:
			let average = (observedConstrainable.frame.width + observedConstrainable.frame.height) * 0.5
			newConstraint = targetAnchor.constraint(equalToConstant: average * ratio + offset)
		}
		newConstraint.priority = priority
		newConstraint.activate()
	}

	private func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect) {
		switch observedLength {
		case .min, .max:
			let isWidthGreaterThanHeight = newFrame.width > newFrame.height
			if isWidthGreaterThanHeight != wasWidthGreatherThanHeight {
				updateUnderlyingConstraint()
			}
		case .average:
			if oldFrame.size != newFrame.size {
				updateUnderlyingConstraint()
			}
		}
	}

	private class InternalDelegate: FrameObservingViewDelegate {
		private unowned let parent: MinMaxLengthConstraint

		init(parent: MinMaxLengthConstraint) {
			self.parent = parent
		}

		func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView) {
			parent.didChangeFrame(from: oldFrame, to: newFrame)
		}
	}
}

public extension Constrainable {
	func width(to observedLength: MinMaxLengthConstraint.ObservedLength, of observedConstrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0) -> MinMaxLengthConstraint {
		return MinMaxLengthConstraint(constrainable: self, targetLength: .width, to: observedConstrainable, observedLength: observedLength, ratio: ratio, offset: offset)
	}

	func height(to observedLength: MinMaxLengthConstraint.ObservedLength, of observedConstrainable: Constrainable, ratio: CGFloat = 1, offset: CGFloat = 0) -> MinMaxLengthConstraint {
		return MinMaxLengthConstraint(constrainable: self, targetLength: .height, to: observedConstrainable, observedLength: observedLength, ratio: ratio, offset: offset)
	}
}
#endif
