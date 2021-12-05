//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol ResolverInitializable {
	init(resolver: Resolver)
}

// NoParameterInitializable
public extension Container {
	func register<Component: NoParameterInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory) {
		register(for: key, storageFactory: storageFactory) { Component() }
	}

	func register<Component: NoParameterInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>) {
		register(for: key, storageFactory: defaultComponentStorageFactory)
	}

	func register<Component: NoParameterInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory) {
		register(for: .init(for: type, variant: variant), storageFactory: storageFactory)
	}

	func register<Component: NoParameterInitializable>(_ type: Component.Type, storageFactory: ComponentStorageFactory) {
		register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory)
	}

	func register<Component: NoParameterInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant) {
		register(type, variant: variant, storageFactory: defaultComponentStorageFactory)
	}

	func register<Component: NoParameterInitializable>(_ type: Component.Type) {
		register(type, storageFactory: defaultComponentStorageFactory)
	}
}

// ResolverInitializable
public extension Container {
	func register<Component: ResolverInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory) {
		register(for: key, storageFactory: storageFactory) { Component(resolver: $0) }
	}

	func register<Component: ResolverInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>) {
		register(for: key, storageFactory: defaultComponentStorageFactory)
	}

	func register<Component: ResolverInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory) {
		register(for: .init(for: type, variant: variant), storageFactory: storageFactory)
	}

	func register<Component: ResolverInitializable>(_ type: Component.Type, storageFactory: ComponentStorageFactory) {
		register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory)
	}

	func register<Component: ResolverInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant) {
		register(type, variant: variant, storageFactory: defaultComponentStorageFactory)
	}

	func register<Component: ResolverInitializable>(_ type: Component.Type) {
		register(type, storageFactory: defaultComponentStorageFactory)
	}
}
