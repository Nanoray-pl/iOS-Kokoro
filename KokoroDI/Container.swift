//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class Container {
	private let parent: Resolver?
	public var defaultComponentStorageFactory: ComponentStorageFactory

	private var components = [AnyComponentKey: UntypedComponentStorage]()

	public init(
		parent: Resolver? = nil,
		defaultComponentStorageFactory: ComponentStorageFactory
	) {
		self.parent = parent
		self.defaultComponentStorageFactory = defaultComponentStorageFactory
	}

	public func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		let storage = storageFactory.createComponentStorage(resolver: self, factory: factory)
		components[.init(from: key)] = .init(wrapping: storage)
	}

	public func unregister<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) {
		components.removeValue(forKey: .init(from: key))
	}
}

public extension Container {
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping (Resolver) -> Component) {
		register(for: key, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: variant), storageFactory: storageFactory, factory: factory)
	}

	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory, factory: factory)
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping (Resolver) -> Component) {
		register(type, variant: variant, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Component>(_ type: Component.Type, factory: @escaping (Resolver) -> Component) {
		register(type, storageFactory: defaultComponentStorageFactory, factory: factory)
	}
}

// registering without `resolver` parameter
public extension Container {
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(for: key, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping () -> Component) {
		register(for: key) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, variant: variant, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping () -> Component) {
		register(type, variant: variant) { _ in factory() }
	}

	func register<Component>(_ type: Component.Type, factory: @escaping () -> Component) {
		register(type) { _ in factory() }
	}
}

// unregistering
public extension Container {
	func unregister<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant) {
		unregister(for: .init(for: type, variant: variant))
	}

	func unregister<Component>(_ type: Component.Type) {
		unregister(for: .init(for: type, variant: VoidComponentKeyVariant.shared))
	}
}

extension Container: Resolver {
	public func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component? {
		return components[.init(from: key)]?.component as? Component ?? parent?.resolveIfPresent(for: key)
	}
}
