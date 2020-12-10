//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class SkeletonEntry: Equatable {
	public enum Style: Equatable {
		case rectangle(cornerRadius: RoundedView.CornerRadius? = nil)
		case ellipse
	}

	public private(set) weak var view: UIView?
	public let style: Style

	public init(masking view: UIView, style: Style) {
		self.view = view
		self.style = style
	}

	public static func == (lhs: SkeletonEntry, rhs: SkeletonEntry) -> Bool {
		return lhs.view === rhs.view && lhs.style == rhs.style
	}
}

public class SkeletonView: UIView {
	private static let startLocations: [NSNumber] = [-1.0, -0.5, 0.0]
	private static let endLocations: [NSNumber] = [1.0, 1.5, 2.0]

	public override class var layerClass: AnyClass {
		return CAGradientLayer.classForCoder()
	}

	private lazy var gradient = layer as! CAGradientLayer

	public var gradientAngle: CGFloat = .pi / 12 { // 30°
		didSet {
			updateGradientPoints()
		}
	}

	public var gradientBackgroundColor = UIColor.systemBackground.withAlphaComponent(0) {
		didSet {
			updateGradientColors()
		}
	}

	public var gradientMovingColor = UIColor.label.withAlphaComponent(0.5) {
		didSet {
			updateGradientColors()
		}
	}

	public var movingAnimationDuration: TimeInterval = 0.8
	public var delayBetweenAnimationLoops: TimeInterval = 1.0

	/// Whether the `SkeletonView` should be visible if it is not currently masking any elements. If this value is `true` and there are currently none masking elements, the `SkeletonView` will be visible on the whole of its `frame`. Defaults to `false`.
	public var masksOnNoElements = false

	/// Whether masking should be done on hidden views (including any of their superviews). Defaults to `true`.
	public var masksHiddenViews = true

	public var animating = true {
		didSet {
			guard animating != oldValue, window != nil else {
				return
			}

			if animating {
				startAnimating()
			} else {
				stopAnimating()
			}
		}
	}

	public var maskEntries = [SkeletonEntry]() {
		didSet {
			if maskEntries != oldValue {
				updateMask()
			}
		}
	}

	public override var isHidden: Bool {
		didSet {
			if isHidden {
				stopAnimating()
			} else if animating {
				startAnimating()
			}
		}
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		buildUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		isUserInteractionEnabled = false

		updateGradientPoints()
		updateGradientColors()
		gradient.locations = Self.startLocations
		clipsToBounds = true
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		updateGradientPoints()
		updateMask()
	}

	public override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)
		if newWindow == nil {
			stopAnimating()
		} else if animating {
			startAnimating()
		}
	}

	public func updateMask() {
		let path = CGMutablePath()

		maskEntries = maskEntries.filter { $0.view != nil }
		maskEntries.forEach {
			guard let view = $0.view else { return }
			if masksHiddenViews || !view.isHiddenIncludingSuperviews {
				let frame = view.convert(view.bounds, to: self)
				switch $0.style {
				case let .rectangle(cornerRadius?):
					let cornerRadiusPoints = cornerRadius.points(for: frame.size)
					path.addRoundedRect(in: frame, cornerWidth: cornerRadiusPoints, cornerHeight: cornerRadiusPoints)
				case .rectangle:
					path.addRect(frame)
				case .ellipse:
					path.addEllipse(in: frame)
				}
			}
		}

		if path.isEmpty && !masksOnNoElements {
			layer.mask = nil
		} else {
			let maskLayer = CAShapeLayer()
			maskLayer.path = path
			layer.mask = maskLayer
		}
	}

	private func updateGradientColors() {
		gradient.colors = [gradientBackgroundColor, gradientMovingColor, gradientBackgroundColor].map(\.cgColor)
	}

	private func updateGradientPoints() {
		let rotatedVector = CGVector(dx: cos(gradientAngle) * frame.width, dy: sin(gradientAngle) * frame.width)
		let center = CGPoint(x: frame.origin.x + frame.size.width * 0.5, y: frame.origin.y + frame.size.height * 0.5)
		let point1 = CGPoint(x: center.x - rotatedVector.dx * 0.5, y: center.y - rotatedVector.dy * 0.5)
		let point2 = CGPoint(x: center.x + rotatedVector.dx * 0.5, y: center.y + rotatedVector.dy * 0.5)
		gradient.startPoint = CGPoint(x: point1.x / frame.width, y: point1.y / frame.height)
		gradient.endPoint = CGPoint(x: point2.x / frame.width, y: point2.y / frame.height)
	}

	private func startAnimating() {
		stopAnimating()
		let animation = CABasicAnimation(keyPath: "locations").with {
			$0.fromValue = SkeletonView.startLocations
			$0.toValue = SkeletonView.endLocations
			$0.duration = movingAnimationDuration
			$0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		}
		let animationGroup = CAAnimationGroup().with {
			$0.duration = movingAnimationDuration + delayBetweenAnimationLoops
			$0.animations = [animation]
			$0.repeatCount = .infinity
		}
		gradient.add(animationGroup, forKey: animation.keyPath)
	}

	private func stopAnimating() {
		gradient.removeAllAnimations()
	}
}
#endif
