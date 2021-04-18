//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public class ProportionalOffsetConstraint: NonBasicConstraint, ObjectWith {
	public enum HorizontalPoint {
		case left, center, right, leading, trailing
	}

	public enum VerticalPoint {
		case top, middle, bottom
	}

	public private(set) var isActive: Bool = false
	public var priority: UILayoutPriority = .required

	private weak var constrainable: Constrainable?
	private weak var anchor: Constrainable?
	public let horizontalPoint: HorizontalPoint?
	public let verticalPoint: VerticalPoint?

	public var ratio: CGSize {
		didSet {
			if isActive {
				deactivate()
				activate()
			}
		}
	}

	public var offset: CGPoint {
		didSet {
			if isActive {
				deactivate()
				activate()
			}
		}
	}

	private weak var helper: UIView? {
		didSet {
			if helper == nil {
				if isActive {
					deactivate()
					activate()
				}
			}
		}
	}

	public convenience init(constrainable: Constrainable, horizontal: HorizontalPoint, to anchor: Constrainable, ratio: CGFloat, offset: CGFloat) {
		self.init(constrainable: constrainable, horizontal: horizontal, vertical: nil, to: anchor, ratio: CGSize(width: ratio, height: 0), offset: CGPoint(x: offset, y: 0))
	}

	public convenience init(constrainable: Constrainable, vertical: VerticalPoint, to anchor: Constrainable, ratio: CGFloat, offset: CGFloat) {
		self.init(constrainable: constrainable, horizontal: nil, vertical: vertical, to: anchor, ratio: CGSize(width: 0, height: ratio), offset: CGPoint(x: 0, y: offset))
	}

	public init(constrainable: Constrainable, horizontal: HorizontalPoint?, vertical: VerticalPoint?, to anchor: Constrainable, ratio: CGSize, offset: CGPoint) {
		self.constrainable = constrainable
		self.anchor = anchor
		horizontalPoint = horizontal
		verticalPoint = vertical
		self.ratio = ratio
		self.offset = offset
	}

	deinit {
		helper?.removeFromSuperview()
	}

	public func activate() {
		guard !isActive else { return }
		isActive = true
		constrainable?.addConstraint(self)
		guard horizontalPoint != nil || verticalPoint != nil else { return }

		guard let constrainable = constrainable, let anchor = anchor else { return }
		guard let common = constrainable.constrainableView.findCommonView(with: anchor.constrainableView) else {
			fatalError("No common superview between views \(constrainable.constrainableView) and \(anchor.constrainableView).")
		}
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		helper = UIView().with {
			$0.isUserInteractionEnabled = false
			common.addSubview($0)

			constraints += [
				$0.left(to: anchor),
				$0.top(to: anchor),
			]

			if let horizontalPoint = horizontalPoint {
				constraints += $0.width(to: anchor, ratio: ratio.width)

				constrainable.prepareForConstraintBasedLayout()
				switch horizontalPoint {
				case .left:
					constraints += constrainable.leftToRight(of: $0).priority(priority)
				case .center:
					constraints += constrainable.centerXToRight(of: $0).priority(priority)
				case .right:
					constraints += constrainable.right(to: $0).priority(priority)
				case .leading:
					constraints += constrainable.leadingAnchor.constraint(equalTo: $0.rightAnchor).priority(priority)
				case .trailing:
					constraints += constrainable.trailingAnchor.constraint(equalTo: $0.rightAnchor).priority(priority)
				}
			} else {
				constraints += $0.width(of: 0)
			}

			if let verticalPoint = verticalPoint {
				constraints += $0.height(to: anchor, ratio: ratio.height)

				constrainable.prepareForConstraintBasedLayout()
				switch verticalPoint {
				case .top:
					constraints += constrainable.topToBottom(of: $0).priority(priority)
				case .middle:
					constraints += constrainable.centerYToBottom(of: $0).priority(priority)
				case .bottom:
					constraints += constrainable.bottom(to: $0).priority(priority)
				}
			} else {
				constraints += $0.height(of: 0)
			}
		}
	}

	public func deactivate() {
		guard isActive else { return }
		isActive = false
		constrainable?.removeConstraint(self)
		helper?.removeFromSuperview()
	}
}

public extension Constrainable {
	func proportionalOffset(horizontal: ProportionalOffsetConstraint.HorizontalPoint, vertical: ProportionalOffsetConstraint.VerticalPoint, to anchor: Constrainable, ratio: CGSize, offset: CGPoint = .zero) -> ProportionalOffsetConstraint {
		return ProportionalOffsetConstraint(constrainable: self, horizontal: horizontal, vertical: vertical, to: anchor, ratio: ratio, offset: offset)
	}

	func proportionalOffset(horizontal: ProportionalOffsetConstraint.HorizontalPoint?, vertical: ProportionalOffsetConstraint.VerticalPoint?, to anchor: Constrainable, relativePoint: CGPoint, offset: CGPoint = .zero) -> ProportionalOffsetConstraint {
		let ratio = CGSize(width: relativePoint.x / anchor.frame.width, height: relativePoint.y / anchor.frame.height)
		return ProportionalOffsetConstraint(constrainable: self, horizontal: horizontal, vertical: vertical, to: anchor, ratio: ratio, offset: offset)
	}

	func horizontalProportionalOffset(_ horizontal: ProportionalOffsetConstraint.HorizontalPoint, to anchor: Constrainable, ratio: CGFloat, offset: CGFloat = 0) -> ProportionalOffsetConstraint {
		return ProportionalOffsetConstraint(constrainable: self, horizontal: horizontal, to: anchor, ratio: ratio, offset: offset)
	}

	func verticalProportionalOffset(_ vertical: ProportionalOffsetConstraint.VerticalPoint, to anchor: Constrainable, ratio: CGFloat, offset: CGFloat = 0) -> ProportionalOffsetConstraint {
		return ProportionalOffsetConstraint(constrainable: self, vertical: vertical, to: anchor, ratio: ratio, offset: offset)
	}
}
#endif
