//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

public extension ResourceProviderFactory {
	func flatMap<NewPublisher>(identifier: String, mapFunction: Identifiable<UUID, (Resource) -> NewPublisher>) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return FlatMapResourceProviderFactory(wrapping: self, identifier: identifier, mapFunction: mapFunction)
	}

	func flatMap<NewPublisher>(identifier: String, mapFunction: @escaping (Resource) -> NewPublisher) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return flatMap(identifier: identifier, mapFunction: .init(mapFunction))
	}
}

public class FlatMapResourceProviderFactory<Factory, NewPublisher>: ResourceProviderFactory where Factory: ResourceProviderFactory, NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Input = Factory.Input
	public typealias Resource = NewPublisher.Output

	private let wrapped: Factory
	private let identifier: String
	private let mapFunction: Identifiable<UUID, (Factory.Resource) -> NewPublisher>

	public init(wrapping wrapped: Factory, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) -> NewPublisher>) {
		self.wrapped = wrapped
		self.identifier = identifier
		self.mapFunction = mapFunction
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return FlatMapResourceProvider<Factory.Resource, NewPublisher>(wrapping: wrapped.create(for: input), identifier: identifier, mapFunction: mapFunction).eraseToAnyResourceProvider()
	}
}

public class FlatMapResourceProvider<OldResource, NewPublisher>: ResourceProvider where NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Resource = NewPublisher.Output

	private let wrapped: AnyResourceProvider<OldResource>
	private let mapperIdentifier: String
	private let mapFunction: Identifiable<UUID, (OldResource) -> NewPublisher>

	public var identifier: String {
		return "FlatMapResourceProvider[identifier: \(mapperIdentifier), value: \(wrapped.identifier)]"
	}

	public init(wrapping wrapped: AnyResourceProvider<OldResource>, identifier: String, mapFunction: Identifiable<UUID, (OldResource) -> NewPublisher>) {
		self.wrapped = wrapped
		mapperIdentifier = identifier
		self.mapFunction = mapFunction
	}

	public func resource() -> AnyPublisher<Resource, Error> {
		return wrapped.resource()
			.flatMap { [mapFunction] in mapFunction.element($0) }
			.eraseToAnyPublisher()
	}

	public static func == (lhs: FlatMapResourceProvider<OldResource, NewPublisher>, rhs: FlatMapResourceProvider<OldResource, NewPublisher>) -> Bool {
		return lhs.mapperIdentifier == rhs.mapperIdentifier && lhs.wrapped == rhs.wrapped && lhs.mapFunction == rhs.mapFunction
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(mapperIdentifier)
		hasher.combine(wrapped)
		hasher.combine(mapFunction)
	}
}
#endif
