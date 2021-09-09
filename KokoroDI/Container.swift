//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class Container {
	private let parent: Resolver?
	public var defaultComponentStorageFactory: ComponentStorageFactory
	public var defaultObjectComponentStorageFactory: ObjectComponentStorageFactory

	private var components = [AnyComponentKey: UntypedComponentStorage]()

	public init(
		parent: Resolver? = nil,
		defaultComponentStorageFactory: ComponentStorageFactory,
		defaultObjectComponentStorageFactory: ObjectComponentStorageFactory
	) {
		self.parent = parent
		self.defaultComponentStorageFactory = defaultComponentStorageFactory
		self.defaultObjectComponentStorageFactory = defaultObjectComponentStorageFactory
	}

	public func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		let storage = storageFactory.createComponentStorage(resolver: self, factory: factory)
		components[.init(from: key)] = .init(wrapping: storage)
	}

	public func register<Component: AnyObject, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ObjectComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		let storage = storageFactory.createObjectComponentStorage(resolver: self, factory: factory)
		components[.init(from: key)] = .init(wrapping: storage)
	}

	public func unregister<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) {
		components.removeValue(forKey: .init(from: key))
	}
}

public extension Container {
	convenience init(
		parent: Container? = nil,
		defaultComponentStorageFactory: ComponentStorageFactory
	) {
		self.init(
			parent: parent,
			defaultComponentStorageFactory: defaultComponentStorageFactory,
			defaultObjectComponentStorageFactory: defaultComponentStorageFactory
		)
	}

	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping (Resolver) -> Component) {
		register(for: key, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Component: AnyObject, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping (Resolver) -> Component) {
		register(for: key, storageFactory: defaultObjectComponentStorageFactory, factory: factory)
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: variant), storageFactory: storageFactory, factory: factory)
	}

	func register<Component: AnyObject, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ObjectComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: variant), storageFactory: storageFactory, factory: factory)
	}

	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory, factory: factory)
	}

	func register<Component: AnyObject>(_ type: Component.Type, storageFactory: ObjectComponentStorageFactory, factory: @escaping (Resolver) -> Component) {
		register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory, factory: factory)
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping (Resolver) -> Component) {
		register(type, variant: variant, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Component: AnyObject, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping (Resolver) -> Component) {
		register(type, variant: variant, storageFactory: defaultObjectComponentStorageFactory, factory: factory)
	}

	func register<Component>(_ type: Component.Type, factory: @escaping (Resolver) -> Component) {
		register(type, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Component: AnyObject>(_ type: Component.Type, factory: @escaping (Resolver) -> Component) {
		register(type, storageFactory: defaultObjectComponentStorageFactory, factory: factory)
	}
}

// registering without `resolver` parameter
public extension Container {
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(for: key, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component: AnyObject, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ObjectComponentStorageFactory, factory: @escaping () -> Component) {
		register(for: key, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping () -> Component) {
		register(for: key) { _ in factory() }
	}

	func register<Component: AnyObject, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping () -> Component) {
		register(for: key) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, variant: variant, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component: AnyObject, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ObjectComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, variant: variant, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component: AnyObject>(_ type: Component.Type, storageFactory: ObjectComponentStorageFactory, factory: @escaping () -> Component) {
		register(type, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping () -> Component) {
		register(type, variant: variant) { _ in factory() }
	}

	func register<Component: AnyObject, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping () -> Component) {
		register(type, variant: variant) { _ in factory() }
	}

	func register<Component>(_ type: Component.Type, factory: @escaping () -> Component) {
		register(type) { _ in factory() }
	}

	func register<Component: AnyObject>(_ type: Component.Type, factory: @escaping () -> Component) {
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
