//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ProgressBar: UIView {
	public enum Direction: Hashable {
		case leftToRight, rightToLeft, leadingToTrailing, trailingToLeading, bottomToTop, topToBottom
	}

	public var direction: Direction {
		didSet {
			updateDirection()
		}
	}

	public var colors: [(location: Double, color: UIColor)] = [(location: 0, color: .systemBlue), (location: 1, color: .systemBlue)] {
		didSet {
			updateColors()
		}
	}

	public var isScalingGradientWithValue = false {
		didSet {
			updateColors()
		}
	}

	public var value: Double = 0 {
		didSet {
			updateValue()
		}
	}

	private var gradient: GradientView!

	private var gradientConstraints: [NSLayoutConstraint] = [] {
		didSet {
			oldValue.deactivate()
			gradientConstraints.activate()
		}
	}

	private var gradientLengthConstraint: NSLayoutConstraint! {
		didSet {
			oldValue?.deactivate()
			gradientLengthConstraint.activate()
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
		backgroundColor = .systemGray4

		gradient = GradientView().with { [parent = self] in
			$0.clipsToBounds = true
			parent.addSubview($0)
		}

		updateDirection()
		updateColors()
	}

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if [.leadingToTrailing, .trailingToLeading].contains(direction) {
			updateDirection()
		}
	}

	public func setSingleColor(_ color: UIColor) {
		colors = [(location: 0, color: color), (location: 1, color: color)]
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
			gradientConstraints = [
				[gradient.left(to: gradient.superview!)],
				gradient.verticalEdges(to: gradient.superview!),
			].flatMap { $0 }
		case .rightToLeft:
			gradient.startPoint = .init(x: 1, y: 0.5)
			gradient.endPoint = .init(x: 0, y: 0.5)
			gradientConstraints = [
				[gradient.right(to: gradient.superview!)],
				gradient.verticalEdges(to: gradient.superview!),
			].flatMap { $0 }
		case .bottomToTop:
			gradient.startPoint = .init(x: 0.5, y: 1)
			gradient.endPoint = .init(x: 0.5, y: 0)
			gradientConstraints = [
				[gradient.bottom(to: gradient.superview!)],
				gradient.horizontalEdges(to: gradient.superview!),
			].flatMap { $0 }
		case .topToBottom:
			gradient.startPoint = .init(x: 0.5, y: 0)
			gradient.endPoint = .init(x: 0.5, y: 1)
			gradientConstraints = [
				[gradient.top(to: gradient.superview!)],
				gradient.horizontalEdges(to: gradient.superview!),
			].flatMap { $0 }
		case .leadingToTrailing, .trailingToLeading:
			fatalError("Invalid state - cases already handled before")
		}

		updateValue()
	}

	private func updateValue() {
		if isScalingGradientWithValue {
			updateColors()
		}
		switch direction {
		case .leftToRight, .rightToLeft, .leadingToTrailing, .trailingToLeading:
			gradientLengthConstraint = gradient.width(to: gradient.superview!, ratio: CGFloat(min(max(value, 0), 1)))
		case .bottomToTop, .topToBottom:
			gradientLengthConstraint = gradient.height(to: gradient.superview!, ratio: CGFloat(min(max(value, 0), 1)))
		}
		layoutIfNeeded()
	}

	private func updateColors() {
		var colors = self.colors
		if !isScalingGradientWithValue && value > 0 {
			colors = colors.map { (location: $0.location / value, color: $0.color) }
		}
		gradient.colors = colors
	}
}
#endif
