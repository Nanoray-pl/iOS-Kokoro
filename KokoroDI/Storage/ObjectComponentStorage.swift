//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public protocol ObjectComponentStorage: ComponentStorage where Component: AnyObject {}

public struct AnyObjectComponentStorage<Component: AnyObject>: ObjectComponentStorage {
	private let componentClosure: () -> Component

	public var component: Component {
		return componentClosure()
	}

	init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: ComponentStorage, Wrapped.Component == Component {
		componentClosure = { wrapped.component }
	}
}

public extension ObjectComponentStorage {
	func eraseToAnyObjectComponentStorage() -> AnyObjectComponentStorage<Component> {
		return (self as? AnyObjectComponentStorage<Component>) ?? .init(wrapping: self)
	}
}

public protocol ObjectComponentStorageFactory {
	func createObjectComponentStorage<Component: AnyObject>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyObjectComponentStorage<Component>
}
