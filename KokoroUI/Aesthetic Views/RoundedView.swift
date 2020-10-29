//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

open class RoundedView: UIView {
	public enum Rounding: Equatable {
		case rectangle(corners: UIRectCorner = .allCorners, radius: CornerRadius = .percentage(1.0))
		case polygon(points: [Point], radius: CornerRadius = .percentage(1.0))

		public struct Point: Equatable {
			public let point: CGPoint
			public let offset: CGVector

			public init(point: CGPoint, offset: CGVector = .zero) {
				self.point = point
				self.offset = offset
			}
		}
	}

	public enum CornerRadius: Equatable {
		case points(_ points: CGFloat)
		case percentage(_ percentage: CGFloat)

		public func points(for size: CGSize) -> CGFloat {
			return points(forEdgeLengths: size.width, size.height)
		}

		public func points(forEdgeLengths length1: CGFloat, _ length2: CGFloat) -> CGFloat {
			let unboundedRadius: CGFloat
			switch self {
			case let .points(points):
				unboundedRadius = points
			case let .percentage(percentage):
				unboundedRadius = percentage * min(length1, length2) * 0.5
			}
			let finalRadius = min(unboundedRadius, length1 * 0.5, length2 * 0.5)
			return finalRadius
		}
	}

	public var rounding: Rounding? = .rectangle() {
		didSet {
			switch rounding {
			case let .polygon(points, _):
				if points.count < 3 {
					fatalError("Rounding with less than 3 points is impossible")
				}
			default:
				break
			}
			updateCornerRadius()
		}
	}

	// double values, because half of the border is masked away
	public var borderWidth: CGFloat {
		get {
			return borderLayer.lineWidth / 2
		}
		set {
			borderLayer.lineWidth = newValue * 2
		}
	}

	public var borderColor: UIColor? {
		get {
			return borderLayer.strokeColor.flatMap { UIColor(cgColor: $0) }
		}
		set {
			borderLayer.strokeColor = newValue?.cgColor
		}
	}

	public override var bounds: CGRect {
		didSet {
			updateCornerRadius()
		}
	}

	private var borderLayer: CAShapeLayer!

	public init() {
		super.init(frame: .zero)
		buildUI()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		layer.masksToBounds = true

		borderLayer = CAShapeLayer().with { [parent = layer] in
			$0.fillColor = nil

			parent.addSublayer($0)
		}

		updateCornerRadius()
	}

	open override func layoutSubviews() {
		super.layoutSubviews()
		borderLayer.frame = bounds
	}

	private func updateCornerRadius() {
		let path = borderPath()
		layer.mask = path.flatMap { path in
			return CAShapeLayer().with {
				$0.path = path
			}
		}
		borderLayer.path = path
	}

	private func borderPath() -> CGPath? {
		switch rounding {
		case let .rectangle(corners, radius):
			let finalRadius = radius.points(for: bounds.size)
			return UIBezierPath(
				roundedRect: bounds,
				byRoundingCorners: corners,
				cornerRadii: CGSize(width: finalRadius, height: finalRadius)
			).cgPath
		case let .polygon(points, radius):
			let scaledPoints = points.map { CGPoint(x: $0.point.x * bounds.width + $0.offset.dx, y: $0.point.y * bounds.height + $0.offset.dy) }
			let path = CGMutablePath()
			path.move(to: scaledPoints.last!)
			for index in 0 ..< scaledPoints.count {
				let point0 = scaledPoints[(index - 1 + scaledPoints.count) % scaledPoints.count]
				let point1 = scaledPoints[index]
				let point2 = scaledPoints[(index + 1) % scaledPoints.count]
				let length1 = sqrt(pow(point0.x - point1.x, 2) + pow(point0.y - point1.y, 2))
				let length2 = sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))
				let radius = radius.points(forEdgeLengths: length1, length2)
				path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
			}
			path.closeSubpath()
			return path
		case .none:
			return nil
		}
	}
}
#endif
