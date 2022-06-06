//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol ResolverInitializable {
	init(resolver: Resolver)
}

// MARK: - NoParameterInitializable

public extension Container {
	@discardableResult
	func register<Component: NoParameterInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: key, storageFactory: storageFactory) { Component() }
	}

	@discardableResult
	func register<Component: NoParameterInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> ContainerRegisterResult {
		return register(for: key, storageFactory: defaultComponentStorageFactory)
	}

	@discardableResult
	func register<Component: NoParameterInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: variant), storageFactory: storageFactory)
	}

	@discardableResult
	func register<Component: NoParameterInitializable>(_ type: Component.Type, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory)
	}

	@discardableResult
	func register<Component: NoParameterInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant) -> ContainerRegisterResult {
		return register(type, variant: variant, storageFactory: defaultComponentStorageFactory)
	}

	@discardableResult
	func register<Component: NoParameterInitializable>(_ type: Component.Type) -> ContainerRegisterResult {
		return register(type, storageFactory: defaultComponentStorageFactory)
	}
}

// MARK: - ResolverInitializable

public extension Container {
	@discardableResult
	func register<Component: ResolverInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: key, storageFactory: storageFactory) { Component(resolver: $0) }
	}

	@discardableResult
	func register<Component: ResolverInitializable, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> ContainerRegisterResult {
		return register(for: key, storageFactory: defaultComponentStorageFactory)
	}

	@discardableResult
	func register<Component: ResolverInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: variant), storageFactory: storageFactory)
	}

	@discardableResult
	func register<Component: ResolverInitializable>(_ type: Component.Type, storageFactory: ComponentStorageFactory) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory)
	}

	@discardableResult
	func register<Component: ResolverInitializable, Variant: Hashable>(_ type: Component.Type, variant: Variant) -> ContainerRegisterResult {
		return register(type, variant: variant, storageFactory: defaultComponentStorageFactory)
	}

	@discardableResult
	func register<Component: ResolverInitializable>(_ type: Component.Type) -> ContainerRegisterResult {
		return register(type, storageFactory: defaultComponentStorageFactory)
	}
}
