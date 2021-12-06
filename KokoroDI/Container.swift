//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class Container: Resolver {
	private let parent: Resolver?
	public var defaultComponentStorageFactory: ComponentStorageFactory

	private var components = [AnyComponentKey: UntypedComponentStorage]()
	private var forwardEntries = [AnyComponentKey: AnyComponentKey]()

	public init(
		parent: Resolver? = nil,
		defaultComponentStorageFactory: ComponentStorageFactory
	) {
		self.parent = parent
		self.defaultComponentStorageFactory = defaultComponentStorageFactory
	}

	@discardableResult
	public func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		let storage = storageFactory.createComponentStorage(resolver: self, factory: factory)
		components[.init(from: key)] = .init(wrapping: storage)
		return TypedContainerRegisterResult(container: self, key: key)
	}

	public func forward<OriginalComponent, OriginalVariant: Hashable, Component, Variant: Hashable>(key: ComponentKey<Component, Variant>, to serviceKey: ComponentKey<OriginalComponent, OriginalVariant>) {
		if components[.init(from: serviceKey)] == nil { fatalError("Cannot forward service \(Component.self) to an unregistered component \(OriginalComponent.self).") }
		forwardEntries[.init(from: key)] = .init(from: serviceKey)
	}

	public func unregister<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) {
		let anyKey = AnyComponentKey(from: key)
		components.removeValue(forKey: anyKey)
		forwardEntries = forwardEntries.filter { $0.key == anyKey || $0.value == anyKey }
	}

	public func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component? {
		let anyKey = AnyComponentKey(from: key)
		if let forwardedKey = forwardEntries[anyKey] {
			if let component = components[forwardedKey]?.component {
				if let typedComponent = component as? Component {
					return typedComponent
				} else {
					fatalError("Forwarded type is not compatible with \(Component.self).")
				}
			}
		}
		return components[anyKey]?.component as? Component ?? parent?.resolveIfPresent(for: key)
	}
}

public extension Container {
	@discardableResult
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		return register(for: key, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	@discardableResult
	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: variant), storageFactory: storageFactory, factory: factory)
	}

	@discardableResult
	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		return register(for: .init(for: type, variant: VoidComponentKeyVariant.shared), storageFactory: storageFactory, factory: factory)
	}

	@discardableResult
	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		return register(type, variant: variant, storageFactory: defaultComponentStorageFactory, factory: factory)
	}

	@discardableResult
	func register<Component>(_ type: Component.Type, factory: @escaping (Resolver) -> Component) -> ContainerRegisterResult {
		return register(type, storageFactory: defaultComponentStorageFactory, factory: factory)
	}
}

// registering without `resolver` parameter
public extension Container {
	@discardableResult
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(for: key, storageFactory: storageFactory) { _ in factory() }
	}

	@discardableResult
	func register<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(for: key) { _ in factory() }
	}

	@discardableResult
	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(type, variant: variant, storageFactory: storageFactory) { _ in factory() }
	}

	@discardableResult
	func register<Component>(_ type: Component.Type, storageFactory: ComponentStorageFactory, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(type, storageFactory: storageFactory) { _ in factory() }
	}

	@discardableResult
	func register<Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(type, variant: variant) { _ in factory() }
	}

	@discardableResult
	func register<Component>(_ type: Component.Type, factory: @escaping () -> Component) -> ContainerRegisterResult {
		return register(type) { _ in factory() }
	}
}

// forwarding
public extension Container {
	func forward<OriginalComponent, OriginalVariant: Hashable, Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, to serviceType: OriginalComponent.Type, variant serviceVariant: OriginalVariant) {
		forward(key: .init(for: type, variant: variant), to: .init(for: serviceType, variant: serviceVariant))
	}

	func forward<OriginalComponent, OriginalVariant: Hashable, Component, Variant: Hashable>(key: ComponentKey<Component, Variant>, to serviceType: OriginalComponent.Type, variant serviceVariant: OriginalVariant) {
		forward(key: key, to: .init(for: serviceType, variant: serviceVariant))
	}

	func forward<OriginalComponent, OriginalVariant: Hashable, Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, to serviceKey: ComponentKey<OriginalComponent, OriginalVariant>) {
		forward(key: .init(for: type, variant: variant), to: serviceKey)
	}

	func forward<OriginalComponent, OriginalVariant: Hashable, Component>(_ type: Component.Type, to serviceKey: ComponentKey<OriginalComponent, OriginalVariant>) {
		forward(key: .init(for: type, variant: VoidComponentKeyVariant.shared), to: serviceKey)
	}

	func forward<OriginalComponent, Component, Variant: Hashable>(key: ComponentKey<Component, Variant>, to serviceType: OriginalComponent.Type) {
		forward(key: key, to: .init(for: serviceType, variant: VoidComponentKeyVariant.shared))
	}

	func forward<OriginalComponent, Component>(_ type: Component.Type, to serviceType: OriginalComponent.Type) {
		forward(key: .init(for: type, variant: VoidComponentKeyVariant.shared), to: .init(for: serviceType, variant: VoidComponentKeyVariant.shared))
	}

	func forward<OriginalComponent, OriginalVariant: Hashable, Component>(_ type: Component.Type, to serviceType: OriginalComponent.Type, variant serviceVariant: OriginalVariant) {
		forward(key: .init(for: type, variant: VoidComponentKeyVariant.shared), to: .init(for: serviceType, variant: serviceVariant))
	}

	func forward<OriginalComponent, Component, Variant: Hashable>(_ type: Component.Type, variant: Variant, to serviceType: OriginalComponent.Type) {
		forward(key: .init(for: type, variant: variant), to: .init(for: serviceType, variant: VoidComponentKeyVariant.shared))
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

public protocol ContainerRegisterResult {
	@discardableResult
	func forwarding<ForwardComponent, ForwardVariant: Hashable>(_ key: ComponentKey<ForwardComponent, ForwardVariant>) -> ContainerRegisterResult
}

private struct TypedContainerRegisterResult<Component, Variant: Hashable>: ContainerRegisterResult {
	private weak var container: Container?
	private let key: ComponentKey<Component, Variant>

	init(container: Container, key: ComponentKey<Component, Variant>) {
		self.container = container
		self.key = key
	}

	@discardableResult
	public func forwarding<ForwardComponent, ForwardVariant: Hashable>(_ key: ComponentKey<ForwardComponent, ForwardVariant>) -> ContainerRegisterResult {
		container?.forward(key: key, to: self.key)
		return self
	}
}

public extension ContainerRegisterResult {
	@discardableResult
	func forwarding<ForwardComponent, ForwardVariant: Hashable>(_ type: ForwardComponent.Type, variant: ForwardVariant) -> ContainerRegisterResult {
		return forwarding(.init(for: type, variant: variant))
	}

	@discardableResult
	func forwarding<ForwardComponent>(_ type: ForwardComponent.Type) -> ContainerRegisterResult {
		return forwarding(.init(for: type, variant: VoidComponentKeyVariant.shared))
	}
}
