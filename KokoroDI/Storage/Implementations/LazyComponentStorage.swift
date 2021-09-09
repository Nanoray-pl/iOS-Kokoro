//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class LazyComponentStorage<Component>: ComponentStorage {
	private unowned let resolver: Resolver
	private let factory: (Resolver) -> Component

	public private(set) lazy var component = factory(resolver)

	public init(resolver: Resolver, factory: @escaping (Resolver) -> Component) {
		self.resolver = resolver
		self.factory = factory
	}
}

public enum LazyComponentStorageFactory: ComponentStorageFactory {
	case shared

	public func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
		return LazyComponentStorage(resolver: resolver, factory: factory)
			.eraseToAnyComponentStorage()
	}
}
