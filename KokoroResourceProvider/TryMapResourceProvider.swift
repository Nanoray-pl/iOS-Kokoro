//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

public extension ResourceProviderFactory {
	// swiftformat:disable:next spaceAroundOperators
	func tryMap<NewResource>(identifier: String, mapFunction: Identifiable<UUID, (Resource) throws -> NewResource>) -> TryMapResourceProviderFactory<Self, NewResource> {
		return TryMapResourceProviderFactory(wrapping: self, identifier: identifier, mapFunction: mapFunction)
	}

	func tryMap<NewResource>(identifier: String, mapFunction: @escaping (Resource) throws -> NewResource) -> TryMapResourceProviderFactory<Self, NewResource> {
		return tryMap(identifier: identifier, mapFunction: .init(mapFunction))
	}
}

public class TryMapResourceProviderFactory<Factory, Resource>: ResourceProviderFactory where Factory: ResourceProviderFactory {
	public typealias Input = Factory.Input

	private let wrapped: Factory
	private let identifier: String
	// swiftformat:disable:next spaceAroundOperators
	private let mapFunction: Identifiable<UUID, (Factory.Resource) throws -> Resource>

	// swiftformat:disable:next spaceAroundOperators
	public init(wrapping wrapped: Factory, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) throws -> Resource>) {
		self.wrapped = wrapped
		self.identifier = identifier
		self.mapFunction = mapFunction
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return TryMapResourceProvider<Factory.Resource, Resource>(wrapping: wrapped.create(for: input), identifier: identifier, mapFunction: mapFunction).eraseToAnyResourceProvider()
	}
}

public class TryMapResourceProvider<OldResource, Resource>: ResourceProvider {
	private let wrapped: AnyResourceProvider<OldResource>
	private let mapperIdentifier: String
	// swiftformat:disable:next spaceAroundOperators
	private let mapFunction: Identifiable<UUID, (OldResource) throws -> Resource>

	public var identifier: String {
		return "TryMapResourceProvider[identifier: \(mapperIdentifier), value: \(wrapped.identifier)]"
	}

	// swiftformat:disable:next spaceAroundOperators
	public init<Wrapped>(wrapping wrapped: Wrapped, identifier: String, mapFunction: Identifiable<UUID, (OldResource) throws -> Resource>) where Wrapped: ResourceProvider, Wrapped.Resource == OldResource {
		self.wrapped = wrapped.eraseToAnyResourceProvider()
		mapperIdentifier = identifier
		self.mapFunction = mapFunction
	}

	public func resource() -> AnyPublisher<Resource, Error> {
		return wrapped.resource()
			.tryMap { [mapFunction] in try mapFunction.element($0) }
			.eraseToAnyPublisher()
	}

	public static func == (lhs: TryMapResourceProvider<OldResource, Resource>, rhs: TryMapResourceProvider<OldResource, Resource>) -> Bool {
		return lhs.mapperIdentifier == rhs.mapperIdentifier && lhs.wrapped == rhs.wrapped && lhs.mapFunction == rhs.mapFunction
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(mapperIdentifier)
		hasher.combine(wrapped)
		hasher.combine(mapFunction)
	}
}
#endif
