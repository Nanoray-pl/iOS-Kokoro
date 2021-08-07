//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public protocol ResourceProvider: AnyObject, Hashable {
	associatedtype Resource

	var identifier: String { get }

	func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?)
	func resource() -> AnyPublisher<Resource, Error>
}

public extension ResourceProvider {
	func resource() -> AnyPublisher<Resource, Error> {
		return resourceAndAwaitTimeMagnitude().resource
	}
}

public final class AnyResourceProvider<Resource>: ResourceProvider {
	private let hashable: AnyHashable
	private let identifierClosure: () -> String
	private let publisherClosure: () -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?)

	public var identifier: String {
		return identifierClosure()
	}

	public init<T: ResourceProvider>(wrapping wrapped: T) where T.Resource == Resource {
		hashable = AnyHashable(wrapped)
		identifierClosure = { [unowned wrapped] in wrapped.identifier }
		publisherClosure = { [unowned wrapped] in wrapped.resourceAndAwaitTimeMagnitude() }
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		return publisherClosure()
	}

	public static func == (lhs: AnyResourceProvider<Resource>, rhs: AnyResourceProvider<Resource>) -> Bool {
		return lhs.hashable == rhs.hashable
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(hashable)
	}
}

public extension ResourceProvider {
	func eraseToAnyResourceProvider() -> AnyResourceProvider<Resource> {
		return (self as? AnyResourceProvider<Resource>) ?? .init(wrapping: self)
	}
}
#endif
