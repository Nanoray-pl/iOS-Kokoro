//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

public protocol NSManagedObjectIDConvertible: CVarArgConvertible {
	func asNSManagedObjectID() -> NSManagedObjectID
}

public extension NSManagedObjectIDConvertible {
	func asCVarArg() -> CVarArg {
		return asNSManagedObjectID()
	}
}

extension NSManagedObjectID: NSManagedObjectIDConvertible {
	public func asNSManagedObjectID() -> NSManagedObjectID {
		return self
	}
}

extension NSManagedObject: NSManagedObjectIDConvertible {
	public func asNSManagedObjectID() -> NSManagedObjectID {
		return objectID
	}
}

public func == <ResultType: NSManagedObject & ManagedObject, ElementType: NSManagedObject & ManagedObject>(lhs: KeyPath<ResultType, ElementType>, rhs: NSManagedObjectIDConvertible?) -> RawPredicateBuilder<ResultType> {
	if let rhs = rhs {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) == %@", rhs)
	} else {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) == nil")
	}
}

public func == <ResultType: NSManagedObject & ManagedObject, ElementType: NSManagedObject & ManagedObject>(lhs: KeyPath<ResultType, ElementType?>, rhs: NSManagedObjectIDConvertible?) -> RawPredicateBuilder<ResultType> {
	if let rhs = rhs {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) == %@", rhs)
	} else {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) == nil")
	}
}

public func != <ResultType: NSManagedObject & ManagedObject, ElementType: NSManagedObject & ManagedObject>(lhs: KeyPath<ResultType, ElementType>, rhs: NSManagedObjectIDConvertible?) -> RawPredicateBuilder<ResultType> {
	if let rhs = rhs {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) != %@", rhs)
	} else {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) != nil")
	}
}

public func != <ResultType: NSManagedObject & ManagedObject, ElementType: NSManagedObject & ManagedObject>(lhs: KeyPath<ResultType, ElementType?>, rhs: NSManagedObjectIDConvertible?) -> RawPredicateBuilder<ResultType> {
	if let rhs = rhs {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) != %@", rhs)
	} else {
		return .init(format: "\(NSExpression(forKeyPath: lhs).keyPath) != nil")
	}
}
#endif
