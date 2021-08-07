//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroCache
import KokoroResourceProvider
import KokoroUtils

public extension ResourceProviderFactory {
	func caching<CacheType>(in cache: CacheType, awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String) -> CacheResourceProviderFactory<Self> where CacheType: Cache, CacheType.Key == AnyResourceProvider<Resource>, CacheType.Value == Resource {
		return CacheResourceProviderFactory(wrapping: self, awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, cache: cache)
	}
}

public class CacheResourceProviderFactory<Factory: ResourceProviderFactory>: ResourceProviderFactory {
	public typealias Input = Factory.Input
	public typealias Resource = Factory.Resource

	private let wrapped: Factory
	private let awaitTimeMagnitude: AwaitTimeMagnitude
	private let identifier: String
	private let cache: AnyCache<AnyResourceProvider<Resource>, Resource>

	public init<CacheType>(wrapping wrapped: Factory, awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, cache: CacheType) where CacheType: Cache, CacheType.Key == AnyResourceProvider<Resource>, CacheType.Value == Resource {
		self.wrapped = wrapped
		self.awaitTimeMagnitude = awaitTimeMagnitude
		self.identifier = identifier
		self.cache = cache.eraseToAnyCache()
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return CacheResourceProvider<Input, Resource>(wrapping: wrapped.create(for: input), awaitTimeMagnitude: awaitTimeMagnitude, identifier: identifier, cache: cache).eraseToAnyResourceProvider()
	}
}

public class CacheResourceProvider<Input, Resource>: ResourceProvider {
	private let wrapped: AnyResourceProvider<Resource>
	private let awaitTimeMagnitude: AwaitTimeMagnitude
	private let cacheIdentifier: String
	private let cache: AnyCache<AnyResourceProvider<Resource>, Resource>

	public var identifier: String {
		return "CacheResourceProvider[identifier: \(cacheIdentifier), value: \(wrapped.identifier)]"
	}

	public init<Wrapped>(wrapping wrapped: Wrapped, awaitTimeMagnitude: AwaitTimeMagnitude, identifier: String, cache: AnyCache<AnyResourceProvider<Resource>, Resource>) where Wrapped: ResourceProvider, Wrapped.Resource == Resource {
		self.wrapped = wrapped.eraseToAnyResourceProvider()
		self.awaitTimeMagnitude = awaitTimeMagnitude
		cacheIdentifier = identifier
		self.cache = cache
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		if let cached = cache.value(for: wrapped) {
			return (
				resource: Just(cached)
					.setFailureType(to: Error.self)
					.eraseToAnyPublisher(),
				awaitTimeMagnitude: awaitTimeMagnitude
			)
		} else {
			let wrappedResult = self.wrapped.resourceAndAwaitTimeMagnitude()
			return (
				resource: wrappedResult.resource
					.onOutput { [cache, wrapped] in cache.store($0, for: wrapped) }
					.eraseToAnyPublisher(),
				awaitTimeMagnitude: wrappedResult.awaitTimeMagnitude
			)
		}
	}

	public static func == (lhs: CacheResourceProvider<Input, Resource>, rhs: CacheResourceProvider<Input, Resource>) -> Bool {
		return lhs.cacheIdentifier == rhs.cacheIdentifier && lhs.wrapped == rhs.wrapped && lhs.cache == rhs.cache
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(cacheIdentifier)
		hasher.combine(wrapped)
	}
}
#endif
