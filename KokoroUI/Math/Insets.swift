//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol EdgeInsets {
	var top: CGFloat { get set }
	var bottom: CGFloat { get set }
	var leading: CGFloat { get set }
	var trailing: CGFloat { get set }

	var vertical: CGFloat { get }
	var horizontal: CGFloat { get }

	var typed: TypedEdgeInsets { get }

	func left(isRightToLeft: Bool) -> CGFloat
	func right(isRightToLeft: Bool) -> CGFloat

	mutating func setLeft(to value: CGFloat, isRightToLeft: Bool)
	mutating func setRight(to value: CGFloat, isRightToLeft: Bool)
}

public enum TypedEdgeInsets: Equatable {
	case simple(_ insets: UIEdgeInsets)
	case directional(_ insets: NSDirectionalEdgeInsets)
}

public extension EdgeInsets {
	var vertical: CGFloat {
		return top + bottom
	}
}

extension UIEdgeInsets: EdgeInsets {
	public var horizontal: CGFloat {
		return left + right
	}

	public var leading: CGFloat {
		get {
			return left
		}
		set {
			left = newValue
		}
	}

	public var trailing: CGFloat {
		get {
			return right
		}
		set {
			right = newValue
		}
	}

	public var typed: TypedEdgeInsets {
		return .simple(self)
	}

	public init(insets: CGFloat) {
		self.init(top: insets, left: insets, bottom: insets, right: insets)
	}

	public func left(isRightToLeft: Bool) -> CGFloat {
		return left
	}

	public func right(isRightToLeft: Bool) -> CGFloat {
		return right
	}

	public mutating func setLeft(to value: CGFloat, isRightToLeft: Bool) {
		left = value
	}

	public mutating func setRight(to value: CGFloat, isRightToLeft: Bool) {
		right = value
	}
}

extension NSDirectionalEdgeInsets: EdgeInsets {
	public var horizontal: CGFloat {
		return leading + trailing
	}

	public var typed: TypedEdgeInsets {
		return .directional(self)
	}

	public init(insets: CGFloat) {
		self.init(top: insets, leading: insets, bottom: insets, trailing: insets)
	}

	public func left(isRightToLeft: Bool) -> CGFloat {
		return isRightToLeft ? trailing : leading
	}

	public func right(isRightToLeft: Bool) -> CGFloat {
		return isRightToLeft ? leading : trailing
	}

	public mutating func setLeft(to value: CGFloat, isRightToLeft: Bool) {
		if isRightToLeft {
			trailing = value
		} else {
			leading = value
		}
	}

	public mutating func setRight(to value: CGFloat, isRightToLeft: Bool) {
		if isRightToLeft {
			leading = value
		} else {
			trailing = value
		}
	}
}
#endif
