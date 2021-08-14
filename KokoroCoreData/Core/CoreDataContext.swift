//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(CoreData)
import Combine
import CoreData

/// Represents a Core Data context. This class does not allow performing any actions on the context - instead it acts as the safety gateway. To perform an action, use one of the methods on this class to retrieve a `CoreDataPerformingContext`.
public class CoreDataContext {
	fileprivate let wrapped: NSManagedObjectContext

	public init(wrapping wrapped: NSManagedObjectContext) {
		self.wrapped = wrapped
	}

	/// Synchronously performs a given block on the context’s queue. The `context: CoreDataPerformingContext` passed in the closure wraps a Core Data context as an `unowned` reference, so you should make sure the reference will still be valid by the time the closure is executed.
	@discardableResult
	public func performAndWait<T>(_ block: (_ context: CoreDataPerformingContext) -> T) -> T {
		var result: T!
		let context = CoreDataPerformingContext(wrapping: wrapped)
		wrapped.performAndWait {
			result = block(context)
		}
		return result
	}

	/// Synchronously performs a given block on the context’s queue. The `context: CoreDataPerformingContext` passed in the closure wraps a Core Data context as an `unowned` reference, so you should make sure the reference will still be valid by the time the closure is executed.
	@discardableResult
	public func performAndWait<T>(_ block: (_ context: CoreDataPerformingContext) throws -> T) throws -> T {
		var result: Result<T, Error>!
		let context = CoreDataPerformingContext(wrapping: wrapped)
		wrapped.performAndWait {
			result = Result { try block(context) }
		}
		return try result.get()
	}

	/// Asynchronously performs a given block on the context’s queue. The `context: CoreDataPerformingContext` passed in the closure wraps a Core Data context as an `unowned` reference, so you should make sure the reference will still be valid by the time the closure is executed.
	public func perform(_ block: @escaping (_ context: CoreDataPerformingContext) -> Void) {
		let context = CoreDataPerformingContext(wrapping: wrapped)
		wrapped.perform {
			block(context)
		}
	}

	/// Asynchronously performs a given block on the context’s queue. The `context: CoreDataPerformingContext` passed in the closure wraps a Core Data context as an `unowned` reference, so you should make sure the reference will still be valid by the time the closure is executed.
	public func performPublisher<T>(_ block: @escaping (_ context: CoreDataPerformingContext) throws -> T) -> AnyPublisher<T, Error> {
		var instance: CoreDataContext! = self
		return Deferred {
			return Future { promise in
				instance.perform { context in
					do {
						let result = try block(context)
						promise(.success(result))
					} catch {
						promise(.failure(error))
					}
					instance = nil
				}
			}
		}
		.eraseToAnyPublisher()
	}
}

public class MainThreadCoreDataContext: CoreDataContext {
	public enum Error: Swift.Error {
		case illegalPerformingContextRequestOutsideMainThread
	}

	/// Directly creates a `CoreDataPerformingContext` which can be used for all Core Data operations.
	/// - Warning: The returned context should only be used on a main thread, otherwise the behavior is undefined (but will most likely result in crashes). The main thread check is only performed at the moment of calling this method.
	/// - Throws: `MainThreadCoreDataContext.Error.illegalPerformingContextRequestOutsideMainThread` if this method is not called on a main thread.
	public func performingContextOnMainThread() throws -> CoreDataPerformingContext {
		guard Thread.isMainThread else { throw Error.illegalPerformingContextRequestOutsideMainThread }
		return CoreDataPerformingContext(wrapping: wrapped)
	}
}

public class CoreDataPerformingContext {
	public unowned let wrapped: NSManagedObjectContext

	fileprivate init(wrapping wrapped: NSManagedObjectContext) {
		self.wrapped = wrapped
	}

	public func save() throws {
		try wrapped.save()
	}

	public func object(with id: NSManagedObjectID) throws -> NSManagedObject {
		return try wrapped.existingObject(with: id)
	}

	public func fetch<ResultType: NSManagedObject>(_ request: NSFetchRequest<ResultType>) throws -> [ResultType] {
		return try wrapped.fetch(request)
	}

	public func fetch<ResultType: NSManagedObject & ManagedObject>(_ request: FetchRequest<ResultType>) throws -> [ResultType] {
		return try fetch(request.asNSFetchRequest())
	}

	public func count<ResultType: NSManagedObject>(for request: NSFetchRequest<ResultType>) throws -> Int {
		return try wrapped.count(for: request)
	}

	public func count<ResultType: NSManagedObject & ManagedObject>(for request: FetchRequest<ResultType>) throws -> Int {
		return try count(for: request.asNSFetchRequest())
	}

	public func insert(_ object: NSManagedObject) {
		wrapped.insert(object)
	}

	public func delete(_ object: NSManagedObject) {
		wrapped.delete(object)
	}
}

public extension NSManagedObject {
	convenience init(context: CoreDataPerformingContext) {
		self.init(context: context.wrapped)
	}
}
#endif
