//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct TransientComponentStorage<Component>: ComponentStorage {
	private unowned let resolver: Resolver
	private let factory: (Resolver) -> Component

	public var component: Component {
		return factory(resolver)
	}

	public init(resolver: Resolver, factory: @escaping (Resolver) -> Component) {
		self.resolver = resolver
		self.factory = factory
	}
}

public enum TransientComponentStorageFactory: ComponentStorageFactory {
	case shared

	public func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
		return TransientComponentStorage(resolver: resolver, factory: factory)
			.eraseToAnyComponentStorage()
	}

	public func createComponentStorage<Component>(resolver: Resolver, with component: Component, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
		// ignoring the component, the storage is transient anyway so it would be ignored
		return TransientComponentStorage(resolver: resolver, factory: factory)
			.eraseToAnyComponentStorage()
	}
}
