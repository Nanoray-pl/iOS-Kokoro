//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

/// A `PredicateBuilder` implementation to be used when it is not possible to declare a (part of a) predicate in a type-safe way.
public struct RawPredicateBuilder<ResultType: NSManagedObject & ManagedObject>: PredicateBuilder {
	private let predicate: NSPredicate

	public init(format: String, _ args: CVarArgConvertible...) {
		predicate = NSPredicate(format: format, argumentArray: args.map { $0.asCVarArg() })
	}

	public func build() -> NSPredicate {
		return predicate
	}
}
#endif
