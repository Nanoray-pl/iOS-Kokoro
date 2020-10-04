//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

public extension ResourceProviderFactory {
	func mapPublisher<NewPublisher>(identifier: String, mapFunction: Identifiable<UUID, (AnyPublisher<Resource, Error>) -> NewPublisher>) -> MapPublisherResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return MapPublisherResourceProviderFactory(wrapping: self, identifier: identifier, mapFunction: mapFunction)
	}

	func mapPublisher<NewPublisher>(identifier: String, mapFunction: @escaping (AnyPublisher<Resource, Error>) -> NewPublisher) -> MapPublisherResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return mapPublisher(identifier: identifier, mapFunction: .init(mapFunction))
	}
}

public class MapPublisherResourceProviderFactory<Factory, NewPublisher>: ResourceProviderFactory where Factory: ResourceProviderFactory, NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Input = Factory.Input
	public typealias Resource = NewPublisher.Output

	private let wrapped: Factory
	private let identifier: String
	private let mapFunction: Identifiable<UUID, (AnyPublisher<Factory.Resource, Error>) -> NewPublisher>

	public init(wrapping wrapped: Factory, identifier: String, mapFunction: Identifiable<UUID, (AnyPublisher<Factory.Resource, Error>) -> NewPublisher>) {
		self.wrapped = wrapped
		self.identifier = identifier
		self.mapFunction = mapFunction
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return MapPublisherResourceProvider(wrapping: wrapped.create(for: input), identifier: identifier, mapFunction: mapFunction).eraseToAnyResourceProvider()
	}
}

public class MapPublisherResourceProvider<OldResource, NewPublisher>: ResourceProvider where NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Resource = NewPublisher.Output

	private let wrapped: AnyResourceProvider<OldResource>
	private let mapperIdentifier: String
	private let mapFunction: Identifiable<UUID, (AnyPublisher<OldResource, Error>) -> NewPublisher>

	public var identifier: String {
		return "MapPublisherResourceProvider[identifier: \(mapperIdentifier), value: \(wrapped.identifier)]"
	}

	public init(wrapping wrapped: AnyResourceProvider<OldResource>, identifier: String, mapFunction: Identifiable<UUID, (AnyPublisher<OldResource, Error>) -> NewPublisher>) {
		self.wrapped = wrapped
		mapperIdentifier = identifier
		self.mapFunction = mapFunction
	}

	public func resource() -> AnyPublisher<NewPublisher.Output, Error> {
		return mapFunction.element(wrapped.resource()).eraseToAnyPublisher()
	}

	public static func == (lhs: MapPublisherResourceProvider<OldResource, NewPublisher>, rhs: MapPublisherResourceProvider<OldResource, NewPublisher>) -> Bool {
		return lhs.mapperIdentifier == rhs.mapperIdentifier && lhs.wrapped == rhs.wrapped && lhs.mapFunction == rhs.mapFunction
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(mapperIdentifier)
		hasher.combine(wrapped)
		hasher.combine(mapFunction)
	}
}
#endif
