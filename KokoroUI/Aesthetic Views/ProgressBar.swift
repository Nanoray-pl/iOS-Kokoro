//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ProgressBar: UIView {
	public enum Value: Hashable, ExpressibleByFloatLiteral {
		public typealias FloatLiteralType = Double

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

	public var value = Value.determinate(0.5) {
		didSet {
			updateValue()
		}
	}

	public var rounding: RoundedView.Rounding {
		get {
			return bar.rounding
		}
		set {
			bar.rounding = newValue
		}
	}

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
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		backgroundColor = .systemGray4
		clipsToBounds = true

		spacer = UIView().with { [parent = self] in
			parent.addSubview($0)
		}

		spacerSpacer = UIView().with { [parent = self] in
			parent.addSubview($0)
			constraints += $0.size(to: $0.superview!)
		}

		bar = RoundedView().with { [parent = self] in
			gradient = GradientView().with { [parent = $0] in
				parent.addSubview($0)
				constraints += $0.edges(to: $0.superview!)
			}

			parent.addSubview($0)
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
				bar.verticalEdges(to: bar.superview!),
				spacer.verticalEdges(to: spacer.superview!),
				spacerSpacer.verticalEdges(to: spacerSpacer.superview!),
				[
					spacerSpacer.rightToLeft(of: spacerSpacer.superview!),
					spacer.left(to: spacerSpacer),
					bar.leftToRight(of: spacer),
				],
			].flatMap { $0 }
		case .rightToLeft:
			gradient.startPoint = .init(x: 1, y: 0.5)
			gradient.endPoint = .init(x: 0, y: 0.5)
			directionConstraints = [
				bar.verticalEdges(to: bar.superview!),
				spacer.verticalEdges(to: spacer.superview!),
				spacerSpacer.verticalEdges(to: spacerSpacer.superview!),
				[
					spacerSpacer.leftToRight(of: spacerSpacer.superview!),
					spacer.right(to: spacerSpacer),
					bar.rightToLeft(of: spacer),
				],
			].flatMap { $0 }
		case .bottomToTop:
			gradient.startPoint = .init(x: 0.5, y: 1)
			gradient.endPoint = .init(x: 0.5, y: 0)
			directionConstraints = [
				bar.horizontalEdges(to: bar.superview!),
				spacer.horizontalEdges(to: spacer.superview!),
				spacerSpacer.horizontalEdges(to: spacerSpacer.superview!),
				[
					spacerSpacer.topToBottom(of: spacerSpacer.superview!),
					spacer.bottom(to: spacerSpacer),
					bar.bottomToTop(of: spacer),
				],
			].flatMap { $0 }
		case .topToBottom:
			gradient.startPoint = .init(x: 0.5, y: 0)
			gradient.endPoint = .init(x: 0.5, y: 1)
			directionConstraints = [
				bar.horizontalEdges(to: bar.superview!),
				spacer.horizontalEdges(to: spacer.superview!),
				spacerSpacer.horizontalEdges(to: spacerSpacer.superview!),
				[
					spacerSpacer.bottomToTop(of: spacerSpacer.superview!),
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
			updateGradientLengthConstraint(value: 0.5)
			updateSpacerLengthConstraint(offset: -0.5)
			self.spacer.superview?.layoutIfNeeded()

			indeterminateAnimator = Animated.run(
				duration: 1.5,
				curve: .easeInOut,
				animations: {
					self.updateSpacerLengthConstraint(offset: 1)
					self.spacer.superview?.layoutIfNeeded()
				},
				completion: { [weak self] in
					guard let self = self else { return }
					if self.shouldRepeatIndeterminateAnimation {
						self.updateValue()
					}
				}
			)
		case let .determinate(value):
			updateGradientLengthConstraint(value: value)
			updateSpacerLengthConstraint(offset: 0)
		}
	}

	private func updateSpacerLengthConstraint(offset: Double) {
		switch direction {
		case .leftToRight, .rightToLeft, .leadingToTrailing, .trailingToLeading:
			spacerLengthConstraint = spacer.width(to: spacer.superview!, ratio: CGFloat(1 + offset))
		case .bottomToTop, .topToBottom:
			spacerLengthConstraint = spacer.height(to: spacer.superview!, ratio: CGFloat(1 + offset))
		}
	}

	private func updateGradientLengthConstraint(value: Double) {
		switch direction {
		case .leftToRight, .rightToLeft, .leadingToTrailing, .trailingToLeading:
			barLengthConstraint = bar.width(to: bar.superview!, ratio: CGFloat(value))
		case .bottomToTop, .topToBottom:
			barLengthConstraint = bar.height(to: bar.superview!, ratio: CGFloat(value))
		}
	}
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ProgressBarPreviews: PreviewProvider {
	static var previews: some View {
		Group {
			ForEach([ProgressBar.Direction.leftToRight, ProgressBar.Direction.rightToLeft], id: \.self) { direction in
				representable(size: .init(width: .fixed(200), height: .fixed(8))) {
					ProgressBar(direction: direction).with {
						$0.value = .determinate(0.7)
						$0.colors = [(location: 0, color: .systemBlue), (location: 1, color: .systemRed)]
					}
				}
			}
		}
		Group {
			ForEach([ProgressBar.Direction.bottomToTop, ProgressBar.Direction.topToBottom], id: \.self) { direction in
				representable(size: .init(width: .fixed(8), height: .fixed(200))) {
					ProgressBar(direction: direction).with {
						$0.value = .determinate(0.7)
						$0.colors = [(location: 0, color: .systemBlue), (location: 1, color: .systemRed)]
					}
				}
			}
		}
		representable(size: .init(width: .fixed(200), height: .fixed(8))) {
			ProgressBar(direction: .leftToRight).with {
				$0.value = .indeterminate
				$0.colors = [(location: 0, color: .systemBlue), (location: 1, color: .systemRed)]
			}
		}
	}
}
#endif
#endif
