//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroDI

private protocol ObjectComponentProtocol: AnyObject {}

class ContainerTests: XCTestCase {
	private class Component: ObjectComponentProtocol {}
	private class ComponentSubclass: Component {}

	private class ResolverComponent: ResolverInitializable {
		required init(resolver: Resolver) {}
	}

	private class CallbackComponentStorageFactory: ComponentStorageFactory {
		private let wrapped: ComponentStorageFactory
		private let callback: () -> Void

		init(wrapping wrapped: ComponentStorageFactory, callback: @escaping () -> Void) {
			self.wrapped = wrapped
			self.callback = callback
		}

		func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
			callback()
			return wrapped.createComponentStorage(resolver: resolver, factory: factory)
		}

		func createComponentStorage<Component>(resolver: Resolver, with component: Component, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
			callback()
			return wrapped.createComponentStorage(resolver: resolver, with: component, factory: factory)
		}
	}

	private let storageFactory = LazyComponentStorageFactory.shared

	func testRegisterAndUnregister() {
		let container = Container(defaultComponentStorageFactory: storageFactory)

		XCTAssertNil(container.resolveIfPresent(Int.self))

		container.register(Int.self) { 2 }
		XCTAssertEqual(container.resolveIfPresent(Int.self), 2)

		container.unregister(Int.self)
		XCTAssertNil(container.resolveIfPresent(Int.self))
	}

	func testNoParameterRegister() {
		let container = Container(defaultComponentStorageFactory: storageFactory)

		XCTAssertNil(container.resolveIfPresent(String.self))

		container.register(String.self)
		XCTAssertEqual(container.resolveIfPresent(String.self), "")
	}

	func testResolverParameterRegister() {
		let container = Container(defaultComponentStorageFactory: storageFactory)

		XCTAssertNil(container.resolveIfPresent(ResolverComponent.self))

		container.register(ResolverComponent.self)
		XCTAssertNotNil(container.resolveIfPresent(ResolverComponent.self))
	}

	func testResolvingFromParent() {
		let parentContainer = Container(defaultComponentStorageFactory: storageFactory)
		let childContainer = Container(parent: parentContainer, defaultComponentStorageFactory: storageFactory)

		parentContainer.register(Component.self) { Component() }

		let parentInstance = parentContainer.resolveIfPresent(Component.self)
		let childInstance = childContainer.resolveIfPresent(Component.self)
		XCTAssertIdentical(parentInstance, childInstance)
	}

	func testResolvingFromChild() {
		let parentContainer = Container(defaultComponentStorageFactory: storageFactory)
		let childContainer = Container(parent: parentContainer, defaultComponentStorageFactory: storageFactory)

		childContainer.register(Component.self) { Component() }

		XCTAssertNil(parentContainer.resolveIfPresent(Component.self))
		XCTAssertNotNil(childContainer.resolveIfPresent(Component.self))
	}

	func testOverridenComponent() {
		let parentContainer = Container(defaultComponentStorageFactory: storageFactory)
		let childContainer = Container(parent: parentContainer, defaultComponentStorageFactory: storageFactory)

		parentContainer.register(Component.self) { Component() }
		childContainer.register(Component.self) { Component() }

		let parentInstance = parentContainer.resolveIfPresent(Component.self)
		let childInstance = childContainer.resolveIfPresent(Component.self)
		XCTAssertNotIdentical(parentInstance, childInstance)
	}

	func testValueAndObjectDifferentiation() {
		var weakCounter = 0
		var valueCounter = 0

		let container = Container(
			defaultComponentStorageFactory: CallbackComponentStorageFactory(
				wrapping: WeakComponentStorageFactory(
					valueStorageFactory: CallbackComponentStorageFactory(
						wrapping: storageFactory,
						callback: { valueCounter += 1 }
					)
				),
				callback: { weakCounter += 1 }
			)
		)

		XCTAssertEqual(weakCounter, 0)
		XCTAssertEqual(valueCounter, 0)

		container.register(Int.self) { 0 }
		XCTAssertEqual(weakCounter, 1)
		XCTAssertEqual(valueCounter, 0)

		container.register(Component.self) { Component() }
		XCTAssertEqual(weakCounter, 2)
		XCTAssertEqual(valueCounter, 0)

		container.register(ObjectComponentProtocol.self) { Component() }
		XCTAssertEqual(weakCounter, 3)
		XCTAssertEqual(valueCounter, 0)

		_ = container.resolve(Int.self)
		XCTAssertEqual(weakCounter, 3)
		XCTAssertEqual(valueCounter, 1)

		_ = container.resolve(Component.self)
		XCTAssertEqual(weakCounter, 3)
		XCTAssertEqual(valueCounter, 1)

		_ = container.resolve(ObjectComponentProtocol.self)
		XCTAssertEqual(weakCounter, 3)
		XCTAssertEqual(valueCounter, 1)
	}

	func testForwarding() {
		do {
			let container = Container(defaultComponentStorageFactory: storageFactory)

			container.register(ComponentSubclass.self) { ComponentSubclass() }
			XCTAssertNotNil(container.resolveIfPresent(ComponentSubclass.self))
			XCTAssertNil(container.resolveIfPresent(Component.self))

			container.forward(Component.self, to: ComponentSubclass.self)
			XCTAssertNotNil(container.resolveIfPresent(ComponentSubclass.self))
			XCTAssertNotNil(container.resolveIfPresent(Component.self))
		}

		do {
			let container = Container(defaultComponentStorageFactory: storageFactory)

			container
				.register(ComponentSubclass.self) { ComponentSubclass() }
				.forwarding(Component.self)
			XCTAssertNotNil(container.resolveIfPresent(ComponentSubclass.self))
			XCTAssertNotNil(container.resolveIfPresent(Component.self))
		}
	}
}
