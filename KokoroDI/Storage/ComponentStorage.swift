//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public protocol ComponentStorage {
	associatedtype Component

	var component: Component { get }
}

public struct AnyComponentStorage<Component>: ComponentStorage {
	private let componentClosure: () -> Component

	public var component: Component {
		return componentClosure()
	}

	init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: ComponentStorage, Wrapped.Component == Component {
		componentClosure = { wrapped.component }
	}
}

public extension ComponentStorage {
	func eraseToAnyComponentStorage() -> AnyComponentStorage<Component> {
		return (self as? AnyComponentStorage<Component>) ?? .init(wrapping: self)
	}
}

public protocol ComponentStorageFactory {
	func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component>
	func createComponentStorage<Component>(resolver: Resolver, with component: Component, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component>
}
