//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData)
import CoreData
import KokoroUtils

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
	public struct SortDescriptor {
		public let keyPathString: String
		public let order: KokoroUtils.SortOrder

		public init<T>(keyPath: KeyPath<ResultType, T>, order: KokoroUtils.SortOrder) {
			keyPathString = NSExpression(forKeyPath: keyPath).keyPath
			self.order = order
		}
	}

	public var predicate: AnyPredicateBuilder<ResultType>
	public var sortDescriptors: [SortDescriptor]
	public var limit: Int?
	public var offset: Int

	public init(sortDescriptors: [SortDescriptor] = [], limit: Int? = nil, offset: Int = 0) {
		self.init(predicate: BoolPredicateBuilder<ResultType>.true, sortDescriptors: sortDescriptors, limit: limit, offset: offset)
	}

	public init<P>(predicate: P, sortDescriptors: [SortDescriptor] = [], limit: Int? = nil, offset: Int = 0) where P: PredicateBuilder, P.ResultType == ResultType {
		self.predicate = predicate.eraseToAnyPredicateBuilder()
		self.sortDescriptors = sortDescriptors
		self.limit = limit
		self.offset = offset
	}

	public init(objectID: NSManagedObjectID) {
		self.init(predicate: \ResultType.objectID == objectID, limit: 1)
	}

	public func asNSFetchRequest() -> NSFetchRequest<ResultType> {
		let request = NSFetchRequest<ResultType>(entityName: ResultType.entityName)
		request.predicate = predicate.build()
		request.sortDescriptors = sortDescriptors.map { NSSortDescriptor(key: $0.keyPathString, ascending: $0.order == .ascending) }.nonEmpty
		if let limit = limit {
			request.fetchLimit = limit
		}
		return request
	}
}
#endif
