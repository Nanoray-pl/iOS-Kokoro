//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

public enum BoolPredicateBuilder<ResultType: NSManagedObject & ManagedObject>: PredicateBuilder, ExpressibleByBooleanLiteral {
	case `false`, `true`

	public init(booleanLiteral value: BooleanLiteralType) {
		self = (value ? .true : .false)
	}

	public func build() -> NSPredicate {
		return NSPredicate(value: self == .true)
	}
}
#endif
