//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public protocol ResourceProvider: class, Hashable {
	associatedtype Resource

	var identifier: String { get }

	func resource() -> AnyPublisher<Resource, Error>
}

public final class AnyResourceProvider<Resource>: ResourceProvider {
	private let hashable: AnyHashable
	private let identifierClosure: () -> String
	private let publisherClosure: () -> AnyPublisher<Resource, Error>

	public var identifier: String {
		return identifierClosure()
	}

	public init<T: ResourceProvider>(wrapping wrapped: T) where T.Resource == Resource {
		hashable = AnyHashable(wrapped)
		identifierClosure = { [unowned wrapped] in wrapped.identifier }
		publisherClosure = { [unowned wrapped] in wrapped.resource() }
	}

	public func resource() -> AnyPublisher<Resource, Error> {
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
