//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroDI

class ContainerTests: XCTestCase {
	private class Component {}

	private class ResolverComponent: ResolverInitializable {
		required init(resolver: Resolver) {}
	}

	private class TestStorageFactory: ComponentStorageFactory {
		private let wrapped: ComponentStorageFactory
		private let valueClosure: () -> Void
		private let objectClosure: () -> Void

		init(wrapping wrapped: ComponentStorageFactory, valueClosure: @escaping () -> Void, objectClosure: @escaping () -> Void) {
			self.wrapped = wrapped
			self.valueClosure = valueClosure
			self.objectClosure = objectClosure
		}

		func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
			valueClosure()
			return wrapped.createComponentStorage(resolver: resolver, factory: factory)
		}

		func createObjectComponentStorage<Component: AnyObject>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyObjectComponentStorage<Component> {
			objectClosure()
			return wrapped.createObjectComponentStorage(resolver: resolver, factory: factory)
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
		var valueCounter = 0
		var objectCounter = 0

		let container = Container(
			defaultComponentStorageFactory: TestStorageFactory(
				wrapping: storageFactory,
				valueClosure: { valueCounter += 1 },
				objectClosure: { objectCounter += 1 }
			)
		)

		XCTAssertEqual(valueCounter, 0)
		XCTAssertEqual(objectCounter, 0)

		container.register(Int.self) { 0 }
		XCTAssertEqual(valueCounter, 1)
		XCTAssertEqual(objectCounter, 0)

		container.register(Component.self) { Component() }
		XCTAssertEqual(valueCounter, 1)
		XCTAssertEqual(objectCounter, 1)
	}
}
