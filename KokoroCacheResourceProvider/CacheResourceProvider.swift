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
	func caching(in cache: AnyCache<AnyResourceProvider<Resource>, Resource>, identifier: String) -> CacheResourceProviderFactory<Self> {
		return CacheResourceProviderFactory(wrapping: self, identifier: identifier, cache: cache)
	}
}

public class CacheResourceProviderFactory<Factory: ResourceProviderFactory>: ResourceProviderFactory {
	public typealias Input = Factory.Input
	public typealias Resource = Factory.Resource

	private let wrapped: Factory
	private let identifier: String
	private let cache: AnyCache<AnyResourceProvider<Resource>, Resource>

	public init(wrapping wrapped: Factory, identifier: String, cache: AnyCache<AnyResourceProvider<Resource>, Resource>) {
		self.wrapped = wrapped
		self.identifier = identifier
		self.cache = cache
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return CacheResourceProvider<Input, Resource>(wrapping: wrapped.create(for: input), identifier: identifier, cache: cache).eraseToAnyResourceProvider()
	}
}

public class CacheResourceProvider<Input, Resource>: ResourceProvider {
	private let wrapped: AnyResourceProvider<Resource>
	private let cacheIdentifier: String
	private let cache: AnyCache<AnyResourceProvider<Resource>, Resource>

	public var identifier: String {
		return "CacheResourceProvider[identifier: \(cacheIdentifier), value: \(wrapped.identifier)]"
	}

	public init(wrapping wrapped: AnyResourceProvider<Resource>, identifier: String, cache: AnyCache<AnyResourceProvider<Resource>, Resource>) {
		self.wrapped = wrapped
		cacheIdentifier = identifier
		self.cache = cache
	}

	public func resource() -> AnyPublisher<Resource, Error> {
		return Deferred { [cache, wrapped] () -> AnyPublisher<Resource, Error> in
			if let cached = cache.value(for: wrapped) {
				return Just(cached)
					.setFailureType(to: Error.self)
					.eraseToAnyPublisher()
			} else {
				return wrapped.resource()
					.onOutput { cache.store($0, for: wrapped) }
					.eraseToAnyPublisher()
			}
		}
		.eraseToAnyPublisher()
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
