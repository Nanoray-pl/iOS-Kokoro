//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ProgressBar: UIView {
	public enum Value: Hashable, ExpressibleByFloatLiteral {
		case indeterminate
		case determinate(_ value: Double)

		public init(floatLiteral value: Double) {
			self = .determinate(value)
		}
	}

	public enum Direction: Hashable {
		case leftToRight, rightToLeft, leadingToTrailing, trailingToLeading, bottomToTop, topToBottom
	}

	public var direction: Direction {
		didSet {
			updateDirection()
		}
	}

	public var colors: [(location: Double, color: UIColor?)] = [(location: 0, color: nil), (location: 1, color: nil)] {
		didSet {
			updateColors()
		}
	}

	public private(set) var value = Value.determinate(0.5) {
		didSet {
			updateValue()
		}
	}

	public var rounding: RoundedView.Rounding? {
		didSet {
			roundedView.rounding = rounding
			bar.rounding = rounding
		}
	}

	public override var backgroundColor: UIColor? {
		get {
			return roundedView.backgroundColor
		}
		set {
			roundedView.backgroundColor = newValue
		}
	}

	private var roundedView: RoundedView!
	private var spacer: UIView!
	private var spacerSpacer: UIView!
	private var bar: RoundedView!
	private var gradient: GradientView!

	private var directionConstraints = [NSLayoutConstraint]() {
		didSet {
			oldValue.deactivate()
			directionConstraints.activate()
		}
	}

	private var spacerLengthConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			spacerLengthConstraint?.activate()
		}
	}

	private var barLengthConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			barLengthConstraint?.activate()
		}
	}

	private var shouldRepeatIndeterminateAnimation = true

	private var indeterminateAnimator: UIViewPropertyAnimator? {
		willSet {
			indeterminateAnimator?.with {
				shouldRepeatIndeterminateAnimation = false
				if $0.state == .active {
					$0.stopAnimation(false)
				}
				if $0.state == .stopped {
					$0.finishAnimation(at: .current)
				}
				shouldRepeatIndeterminateAnimation = true
			}
		}
	}

	public init(direction: Direction) {
		self.direction = direction
		super.init(frame: .zero)
		buildUI()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		let constraints = ConstraintSession.current

		roundedView = RoundedView().with { [parent = self] in
			$0.backgroundColor = .systemGray4
			$0.clipsToBounds = true

			spacer = UIView().with { [parent = $0] in
				parent.addSubview($0)
			}

			spacerSpacer = UIView().with { [parent = $0] in
				parent.addSubview($0)
				constraints += $0.sizeToSuperview()
			}

			bar = RoundedView().with { [parent = $0] in
				$0.rounding = nil

				gradient = GradientView().with { [parent = $0] in
					parent.addSubview($0)
					constraints += $0.edgesToSuperview()
				}

				parent.addSubview($0)
			}

			parent.addSubview($0)
			constraints += $0.edgesToSuperview()
		}

		updateColors()
		updateDirection()
	}

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if previousTraitCollection?.layoutDirection != traitCollection.layoutDirection && [.leadingToTrailing, .trailingToLeading].contains(direction) {
			updateDirection()
		}
	}

	public override func tintColorDidChange() {
		super.tintColorDidChange()
		updateColors()
	}

	public func setSingleColor(_ color: UIColor) {
		colors = [(location: 0, color: color), (location: 1, color: color)]
	}

	public func setValue(_ value: Value, animated: Bool) {
		guard value != self.value else { return }
		Animated(booleanLiteral: animated).run {
			self.value = value
			if animated {
				self.layoutIfNeeded()
			}
		}
	}

	private func updateColors() {
		gradient.colors = colors.map { (location: $0.location, color: $0.color ?? tintColor) }
	}

	private func updateDirection() {
		let direction: Direction
		switch self.direction {
		case .leadingToTrailing:
			direction = (traitCollection.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight)
		case .trailingToLeading:
			direction = (traitCollection.layoutDirection == .rightToLeft ? .leftToRight : .rightToLeft)
		case .leftToRight, .rightToLeft, .bottomToTop, .topToBottom:
			direction = self.direction
		}

		switch direction {
		case .leftToRight:
			gradient.startPoint = .init(x: 0, y: 0.5)
			gradient.endPoint = .init(x: 1, y: 0.5)
			directionConstraints = [
				bar.verticalEdgesToSuperview(),
				spacer.verticalEdgesToSuperview(),
				spacerSpacer.verticalEdgesToSuperview(),
				[
					spacerSpacer.rightToLeftOfSuperview(),
					spacer.left(to: spacerSpacer),
					bar.leftToRight(of: spacer),
				],
			].flatMap { $0 }
		case .rightToLeft:
			gradient.startPoint = .init(x: 1, y: 0.5)
			gradient.endPoint = .init(x: 0, y: 0.5)
			directionConstraints = [
				bar.verticalEdgesToSuperview(),
				spacer.verticalEdgesToSuperview(),
				spacerSpacer.verticalEdgesToSuperview(),
				[
					spacerSpacer.leftToRightOfSuperview(),
					spacer.right(to: spacerSpacer),
					bar.rightToLeft(of: spacer),
				],
			].flatMap { $0 }
		case .bottomToTop:
			gradient.startPoint = .init(x: 0.5, y: 1)
			gradient.endPoint = .init(x: 0.5, y: 0)
			directionConstraints = [
				bar.horizontalEdgesToSuperview(),
				spacer.horizontalEdgesToSuperview(),
				spacerSpacer.horizontalEdgesToSuperview(),
				[
					spacerSpacer.topToBottomOfSuperview(),
					spacer.bottom(to: spacerSpacer),
					bar.bottomToTop(of: spacer),
				],
			].flatMap { $0 }
		case .topToBottom:
			gradient.startPoint = .init(x: 0.5, y: 0)
			gradient.endPoint = .init(x: 0.5, y: 1)
			directionConstraints = [
				bar.horizontalEdgesToSuperview(),
				spacer.horizontalEdgesToSuperview(),
				spacerSpacer.horizontalEdgesToSuperview(),
				[
					spacerSpacer.bottomToTopOfSuperview(),
					spacer.top(to: spacerSpacer),
					bar.topToBottom(of: spacer),
				],
			].flatMap { $0 }
		case .leadingToTrailing, .trailingToLeading:
			fatalError("Invalid state - cases already handled before")
		}

		updateValue()
	}

	private func updateValue() {
		indeterminateAnimator = nil

		switch value {
		case .indeterminate:
			updateIndeterminateAnimator(forward: true)
		case let .determinate(value):
			updateGradientLengthConstraint(value: value)
			updateSpacerLengthConstraint(offset: 0)
		}
	}

	private func updateIndeterminateAnimator(forward: Bool) {
		updateGradientLengthConstraint(value: 0.5)
		updateSpacerLengthConstraint(offset: forward ? -0.5 : 1)
		self.spacer.superview?.layoutIfNeeded()

		indeterminateAnimator = Animated.run(
			duration: 1.5,
			curve: .easeInOut,
			animations: {
				self.updateSpacerLengthConstraint(offset: forward ? 1 : -0.5)
				self.spacer.superview?.layoutIfNeeded()
			},
			completion: { [weak self] in
				guard let self = self else { return }
				if self.shouldRepeatIndeterminateAnimation {
					self.updateIndeterminateAnimator(forward: !forward)
				}
			}
		)
	}

	private func updateSpacerLengthConstraint(offset: Double) {
		switch direction {
		case .leftToRight, .rightToLeft, .leadingToTrailing, .trailingToLeading:
			spacerLengthConstraint = spacer.widthToSuperview(ratio: CGFloat(1 + offset))
		case .bottomToTop, .topToBottom:
			spacerLengthConstraint = spacer.heightToSuperview(ratio: CGFloat(1 + offset))
		}
	}

	private func updateGradientLengthConstraint(value: Double) {
		switch direction {
		case .leftToRight, .rightToLeft, .leadingToTrailing, .trailingToLeading:
			barLengthConstraint = bar.widthToSuperview(ratio: CGFloat(value))
		case .bottomToTop, .topToBottom:
			barLengthConstraint = bar.heightToSuperview(ratio: CGFloat(value))
		}
	}
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ProgressBarPreviews: PreviewProvider {
	static var previews: some View {
		Group {
			ForEach([ProgressBar.Direction.leftToRight, ProgressBar.Direction.rightToLeft], id: \.self) { direction in
				representable {
					ProgressBar(direction: direction).with {
						$0.setValue(.determinate(0.7), animated: false)
					}
				}
			}
		}
	}
}
#endif
#endif
