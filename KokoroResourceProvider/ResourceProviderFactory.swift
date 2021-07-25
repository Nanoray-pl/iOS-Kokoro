//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol ResourceProviderFactory: AnyObject {
	associatedtype Input
	associatedtype Resource

	func create(for input: Input) -> AnyResourceProvider<Resource>
}

public extension ResourceProviderFactory {
	func eraseToAnyResourceProviderFactory() -> AnyResourceProviderFactory<Input, Resource> {
		return (self as? AnyResourceProviderFactory<Input, Resource>) ?? AnyResourceProviderFactory(wrapping: self)
	}
}

public final class AnyResourceProviderFactory<Input, Resource>: ResourceProviderFactory {
	private let factoryMethod: (Input) -> AnyResourceProvider<Resource>

	public init<T>(wrapping wrapped: T) where T: ResourceProviderFactory, T.Input == Input, T.Resource == Resource {
		factoryMethod = { wrapped.create(for: $0) }
	}

	public func create(for input: Input) -> AnyResourceProvider<Resource> {
		return factoryMethod(input)
	}
}
