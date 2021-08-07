//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

private let defaultAwaitTimeMagnitude: AwaitTimeMagnitude? = nil

public extension ResourceProviderFactory {
	func flatMap<NewPublisher>(awaitTimeMagnitude: AwaitTimeMagnitude?, identifier: String, mapFunction: Identifiable<UUID, (Resource) -> NewPublisher>) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return FlatMapResourceProviderFactory(wrapping: self, awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	func flatMap<NewPublisher>(awaitTimeMagnitude: AwaitTimeMagnitude?, identifier: String, mapFunction: @escaping (Resource) -> NewPublisher) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return flatMap(awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: .init(mapFunction))
	}

	func flatMap<NewPublisher>(identifier: String, mapFunction: Identifiable<UUID, (Resource) -> NewPublisher>) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return flatMap(awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	func flatMap<NewPublisher>(identifier: String, mapFunction: @escaping (Resource) -> NewPublisher) -> FlatMapResourceProviderFactory<Self, NewPublisher> where NewPublisher: Publisher, NewPublisher.Failure == Error {
		return flatMap(awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}
}

public class FlatMapResourceProviderFactory<Factory, NewPublisher>: ResourceProviderFactory where Factory: ResourceProviderFactory, NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Input = Factory.Input
	public typealias Resource = NewPublisher.Output

	private let wrapped: Factory
	private let awaitTimeMagnitude: AwaitTimeMagnitude?
	private let identifier: String
	private let mapFunction: Identifiable<UUID, (Factory.Resource) -> NewPublisher>

	public init(wrapping wrapped: Factory, awaitTimeMagnitude: AwaitTimeMagnitude?, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) -> NewPublisher>) {
		self.wrapped = wrapped
		self.awaitTimeMagnitude = awaitTimeMagnitude
		self.identifier = identifier
		self.mapFunction = mapFunction
	}

	public convenience init(wrapping wrapped: Factory, identifier: String, mapFunction: Identifiable<UUID, (Factory.Resource) -> NewPublisher>) {
		self.init(wrapping: wrapped, awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return FlatMapResourceProvider<Factory.Resource, NewPublisher>(wrapping: wrapped.create(for: input), awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction).eraseToAnyResourceProvider()
	}
}

public class FlatMapResourceProvider<OldResource, NewPublisher>: ResourceProvider where NewPublisher: Publisher, NewPublisher.Failure == Error {
	public typealias Resource = NewPublisher.Output

	private let wrapped: AnyResourceProvider<OldResource>
	private let awaitTimeMagnitude: AwaitTimeMagnitude?
	private let mapperIdentifier: String
	private let mapFunction: Identifiable<UUID, (OldResource) -> NewPublisher>

	public var identifier: String {
		return "FlatMapResourceProvider[identifier: \(mapperIdentifier), value: \(wrapped.identifier)]"
	}

	public init<Wrapped>(wrapping wrapped: Wrapped, awaitTimeMagnitude: AwaitTimeMagnitude?, identifier: String, mapFunction: Identifiable<UUID, (OldResource) -> NewPublisher>) where Wrapped: ResourceProvider, Wrapped.Resource == OldResource {
		self.wrapped = wrapped.eraseToAnyResourceProvider()
		self.awaitTimeMagnitude = awaitTimeMagnitude
		mapperIdentifier = identifier
		self.mapFunction = mapFunction
	}

	public convenience init<Wrapped>(wrapping wrapped: Wrapped, identifier: String, mapFunction: Identifiable<UUID, (OldResource) -> NewPublisher>) where Wrapped: ResourceProvider, Wrapped.Resource == OldResource {
		self.init(wrapping: wrapped, awaitTimeMagnitude: defaultAwaitTimeMagnitude, identifier: identifier, mapFunction: mapFunction)
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<NewPublisher.Output, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		let wrapped = self.wrapped.resourceAndAwaitTimeMagnitude()
		return (
			resource: wrapped.resource
				.flatMap { [mapFunction] in mapFunction.element($0) }
				.eraseToAnyPublisher(),
			awaitTimeMagnitude: wrapped.awaitTimeMagnitude + awaitTimeMagnitude
		)
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
