//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

/// A button control implementation, which is meant to be used as an abstract class.
///
/// This class observes the appearance of a system button and allows a subclass to change its appearance to look similar to a standard `UIButton`.
///
/// A subclass of this class should add its own visible content views to the `contentView` and optionally override `didChangeWrappedColor(_:)` and/or `didChangeWrappedAlpha(_:)`.
///
/// Additionally, a subclass should call `wrappedButton?.setTitle("<any>", for: .normal)` after completing its setup to trigger `tintColor` update.
open class Button: UIControl {
	public var insets: UIEdgeInsets = .zero {
		didSet {
			topConstraint.constant = insets.top
			bottomConstraint.constant = -insets.bottom
			leftConstraint.constant = insets.left
			rightConstraint.constant = -insets.right
			invalidateIntrinsicContentSize()
		}
	}

	private let modifiesOwnAlpha: Bool

	public private(set) var wrappedButton: UIButton!
	public private(set) var contentView: UIView!

	private var topConstraint: NSLayoutConstraint!
	private var bottomConstraint: NSLayoutConstraint!
	private var leftConstraint: NSLayoutConstraint!
	private var rightConstraint: NSLayoutConstraint!

	private var colorObservation: NSKeyValueObservation?
	private var alphaObservation: NSKeyValueObservation?

	public override var isEnabled: Bool {
		didSet {
			wrappedButton.isEnabled = isEnabled
		}
	}

	public init(type buttonType: UIButton.ButtonType = .system, modifiesOwnAlpha: Bool) {
		self.modifiesOwnAlpha = modifiesOwnAlpha
		super.init(frame: .zero)
		buildUI(type: buttonType)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI(type buttonType: UIButton.ButtonType = .system) {
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		isAccessibilityElement = true
		accessibilityTraits.insert(.button)

		contentView = UIView(frame: .zero).with { [parent = self] in
			parent.addSubview($0)
			topConstraint = $0.top(to: parent)
			bottomConstraint = $0.bottom(to: parent)
			leftConstraint = $0.left(to: parent)
			rightConstraint = $0.right(to: parent)
			constraints += [topConstraint, bottomConstraint, leftConstraint, rightConstraint]
		}

		wrappedButton = UIButton(type: buttonType).with { [parent = self] in
			$0.titleLabel?.layer.mask = CAShapeLayer()
			$0.imageView?.layer.mask = CAShapeLayer()
			$0.addTarget(self, action: #selector(didTouchUpInside), for: .touchUpInside)

			colorObservation = $0.titleLabel?.observe(\.textColor, options: [.new], changeHandler: { [weak self] _, change in
				guard let self = self, let newValue = change.newValue else { return }
				self.didChangeWrappedColor(newValue)
			})

			alphaObservation = $0.titleLabel?.observe(\.alpha, options: [.new], changeHandler: { [weak self] _, change in
				guard let self = self, let newValue = change.newValue else { return }
				self.didChangeWrappedAlpha(newValue)
			})

			parent.addSubview($0)
			constraints += [
				$0.left(to: parent),
				$0.top(to: parent),
				$0.size(to: parent, relation: .greaterThanOrEqual),
				$0.size(to: parent).priority(.defaultLow),
			]
		}
	}

	@objc private func didTouchUpInside() {
		guard isEnabled else { return }
		sendActions(for: .touchUpInside)
	}

	open func didChangeWrappedColor(_ color: UIColor?) {}

	open func didChangeWrappedAlpha(_ alpha: CGFloat) {
		if modifiesOwnAlpha {
			contentView.alpha = alpha
		}
	}
}
#endif
