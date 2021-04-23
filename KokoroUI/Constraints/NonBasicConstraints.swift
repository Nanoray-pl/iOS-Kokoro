//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public protocol NonBasicConstraint: Constraint {}

private var nonBasicConstraintsKey: UInt8 = 0

public extension Constrainable {
	private(set) var nonBasicConstraints: [NonBasicConstraint] {
		get {
			return ((objc_getAssociatedObject(self, &nonBasicConstraintsKey) as? NSArray) as? [NonBasicConstraint]) ?? []
		}
		set {
			if newValue.isEmpty {
				objc_setAssociatedObject(self, &nonBasicConstraintsKey, nil, .OBJC_ASSOCIATION_RETAIN)
			} else {
				objc_setAssociatedObject(self, &nonBasicConstraintsKey, newValue as NSArray, .OBJC_ASSOCIATION_RETAIN)
			}
		}
	}

	func addConstraint(_ constraint: NonBasicConstraint) {
		nonBasicConstraints += [constraint]
	}

	func removeConstraint(_ constraint: NonBasicConstraint) {
		var constraints = nonBasicConstraints
		constraints.removeFirst(where: { $0 === constraint })
		nonBasicConstraints = constraints
	}
}
#endif
