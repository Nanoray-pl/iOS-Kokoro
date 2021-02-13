//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol EdgeInsets {
	var top: CGFloat { get }
	var bottom: CGFloat { get }

	var vertical: CGFloat { get }
	var horizontal: CGFloat { get }

	var typed: TypedEdgeInsets { get }
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

	public var typed: TypedEdgeInsets {
		return .simple(self)
	}

	public init(insets: CGFloat) {
		self.init(top: insets, left: insets, bottom: insets, right: insets)
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
}
#endif
