//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData)
import CoreData

public protocol ManagedObject: AnyObject {
	static var entityName: String { get }
}

/// A base protocol used for building type-safe predicates for Core Data fetch requests.
public protocol PredicateBuilder {
	associatedtype ResultType: NSManagedObject & ManagedObject

	func build() -> NSPredicate
}

public extension PredicateBuilder {
	func eraseToAnyPredicateBuilder() -> AnyPredicateBuilder<ResultType> {
		return (self as? AnyPredicateBuilder<ResultType>) ?? AnyPredicateBuilder(wrapping: self)
	}
}

public class AnyPredicateBuilder<ResultType: NSManagedObject & ManagedObject>: PredicateBuilder {
	private let builder: () -> NSPredicate

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: PredicateBuilder, Wrapped.ResultType == ResultType {
		builder = { wrapped.build() }
	}

	public func build() -> NSPredicate {
		return builder()
	}
}

public protocol CVarArgConvertible {
	func asCVarArg() -> CVarArg
}

extension Int: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension Int16: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension Int32: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension Int64: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension String: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self
	}
}

extension Bool: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension Double: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as NSNumber
	}
}

extension Date: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as CVarArg
	}
}

extension UUID: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return uuidString
	}
}

extension NSManagedObjectID: CVarArgConvertible {
	public func asCVarArg() -> CVarArg {
		return self as CVarArg
	}
}

public struct FetchRequest<ResultType: NSManagedObject & ManagedObject> {
	public var predicate: AnyPredicateBuilder<ResultType>
	public var limit: Int?

	public init(limit: Int? = nil) {
		self.init(predicate: BoolPredicateBuilder<ResultType>.true, limit: limit)
	}

	public init<P>(predicate: P, limit: Int? = nil) where P: PredicateBuilder, P.ResultType == ResultType {
		self.predicate = predicate.eraseToAnyPredicateBuilder()
		self.limit = limit
	}

	public init(objectID: NSManagedObjectID) {
		self.init(predicate: \ResultType.objectID == objectID, limit: 1)
	}

	public func asNSFetchRequest() -> NSFetchRequest<ResultType> {
		let request = NSFetchRequest<ResultType>(entityName: ResultType.entityName)
		request.predicate = predicate.build()
		if let limit = limit {
			request.fetchLimit = limit
		}
		return request
	}
}
#endif
