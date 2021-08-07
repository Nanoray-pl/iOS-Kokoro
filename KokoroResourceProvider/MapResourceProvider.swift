//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

private let defaultAwaitTimeMagnitude = AwaitTimeMagnitude.computational

public extension ResourceProviderFactory {
	func map<NewResource>(awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, mapFunction: Identifiable<UUID, (Resource) -> NewResource>) -> MapResourceProviderFactory<Self, NewResource> {
		return MapResourceProviderFactory(wrapping: self, awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	func map<NewResource>(awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, mapFunction: @escaping (Resource) -> NewResource) -> MapResourceProviderFactory<Self, NewResource> {
		return map(awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: .init(mapFunction))
	}

	func map<NewResource>(identifier: String, mapFunction: Identifiable<UUID, (Resource) -> NewResource>) -> MapResourceProviderFactory<Self, NewResource> {
		return map(awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	func map<NewResource>(identifier: String, mapFunction: @escaping (Resource) -> NewResource) -> MapResourceProviderFactory<Self, NewResource> {
		return map(awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}
}

public class MapResourceProviderFactory<Factory, Resource>: ResourceProviderFactory where Factory: ResourceProviderFactory {
	public typealias Input = Factory.Input

	private let wrapped: Factory
	private let awaitTimeMagnitude: AwaitTimeMagnitude
	private let identifier: String
	private let mapFunction: Identifiable<UUID, (Factory.Resource) -> Resource>

	public init(wrapping wrapped: Factory, awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) -> Resource>) {
		self.wrapped = wrapped
		self.awaitTimeMagnitude = awaitTimeMagnitude
		self.identifier = identifier
		self.mapFunction = mapFunction
	}

	public convenience init(wrapping wrapped: Factory, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) -> Resource>) {
		self.init(wrapping: wrapped, awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return MapResourceProvider<Factory.Resource, Resource>(wrapping: wrapped.create(for: input), awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction).eraseToAnyResourceProvider()
	}
}

public class MapResourceProvider<OldResource, Resource>: ResourceProvider {
	private let wrapped: AnyResourceProvider<OldResource>
	private let awaitTimeMagnitude: AwaitTimeMagnitude
	private let mapperIdentifier: String
	private let mapFunction: Identifiable<UUID, (OldResource) -> Resource>

	public var identifier: String {
		return "MapResourceProvider[identifier: \(mapperIdentifier), value: \(wrapped.identifier)]"
	}

	public init<Wrapped>(wrapping wrapped: Wrapped, awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, mapFunction: Identifiable<UUID, (OldResource) -> Resource>) where Wrapped: ResourceProvider, Wrapped.Resource == OldResource {
		self.wrapped = wrapped.eraseToAnyResourceProvider()
		self.awaitTimeMagnitude = awaitTimeMagnitude
		mapperIdentifier = identifier
		self.mapFunction = mapFunction
	}

	public convenience init<Wrapped>(wrapping wrapped: Wrapped, identifier: String, mapFunction: Identifiable<UUID, (OldResource) -> Resource>) where Wrapped: ResourceProvider, Wrapped.Resource == OldResource {
		self.init(wrapping: wrapped, awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		let wrapped = self.wrapped.resourceAndAwaitTimeMagnitude()
		return (
			resource: wrapped.resource
				.map { [mapFunction] in mapFunction.element($0) }
				.eraseToAnyPublisher(),
			awaitTimeMagnitude: wrapped.awaitTimeMagnitude + awaitTimeMagnitude
		)
	}

	public static func == (lhs: MapResourceProvider<OldResource, Resource>, rhs: MapResourceProvider<OldResource, Resource>) -> Bool {
		return lhs.mapperIdentifier == rhs.mapperIdentifier && lhs.wrapped == rhs.wrapped && lhs.mapFunction == rhs.mapFunction
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(mapperIdentifier)
		hasher.combine(wrapped)
		hasher.combine(mapFunction)
	}
}
#endif
