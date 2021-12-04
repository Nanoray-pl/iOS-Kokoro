//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol ComponentVariant: Hashable {
	associatedtype Component
}

public extension Resolver {
	func resolveIfPresent<Variant: ComponentVariant>(_ variant: Variant) -> Variant.Component? {
		return resolveIfPresent(for: .init(for: Variant.Component.self, variant: variant))
	}

	func resolve<Variant: ComponentVariant>(_ variant: Variant) -> Variant.Component {
		return resolve(for: .init(for: Variant.Component.self, variant: variant))
	}
}

public extension Container {
	func register<Variant: ComponentVariant>(_ variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Variant.Component) {
		register(Variant.Component.self, variant: variant, storageFactory: storageFactory, factory: factory)
	}

	func register<Variant>(_ variant: Variant, storageFactory: ObjectComponentStorageFactory, factory: @escaping (Resolver) -> Variant.Component) where Variant: ComponentVariant, Variant.Component: AnyObject {
		register(Variant.Component.self, variant: variant, storageFactory: storageFactory, factory: factory)
	}

	func register<Variant: ComponentVariant>(_ variant: Variant, factory: @escaping (Resolver) -> Variant.Component) {
		register(Variant.Component.self, variant: variant, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	func register<Variant>(_ variant: Variant, factory: @escaping (Resolver) -> Variant.Component) where Variant: ComponentVariant, Variant.Component: AnyObject {
		register(Variant.Component.self, variant: variant, storageFactory: defaultObjectComponentStorageFactory, factory: factory)
	}

	func unregister<Variant: ComponentVariant>(_ variant: Variant) {
		unregister(for: .init(for: Variant.Component.self, variant: variant))
	}
}

// registering without `resolver` parameter
public extension Container {
	func register<Variant: ComponentVariant>(_ variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping () -> Variant.Component) {
		register(variant, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Variant>(_ variant: Variant, storageFactory: ObjectComponentStorageFactory, factory: @escaping () -> Variant.Component) where Variant: ComponentVariant, Variant.Component: AnyObject {
		register(variant, storageFactory: storageFactory) { _ in factory() }
	}

	func register<Variant: ComponentVariant>(_ variant: Variant, factory: @escaping () -> Variant.Component) {
		register(variant) { _ in factory() }
	}

	func register<Variant>(_ variant: Variant, factory: @escaping () -> Variant.Component) where Variant: ComponentVariant, Variant.Component: AnyObject {
		register(variant) { _ in factory() }
	}
}

#if canImport(Foundation)
public extension AnyInject {
	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}

public extension AnyInject where EnclosingSelf: HasResolver {
	init(resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}

public extension AnyProjectedValueInject {
	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}

public extension AnyProjectedValueInject where EnclosingSelf: HasResolver {
	init(resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}

public extension AnyReadOnlyProjectedValueInject {
	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}

public extension AnyReadOnlyProjectedValueInject where EnclosingSelf: HasResolver {
	init(resolve resolveMode: AnyInjectResolveMode = .once, _ variant: Variant, synchronization: Synchronization = .shared) where Variant: ComponentVariant, Variant.Component == Component {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Variant.Component.self, variant: variant), synchronization: synchronization)
	}
}
#endif
