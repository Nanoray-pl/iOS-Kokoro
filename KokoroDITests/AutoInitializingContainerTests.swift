//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils
import XCTest
@testable import KokoroDI

class AutoInitializingContainerTests: XCTestCase {
	private class UnmarkedComponent {}

	private class NoParameterComponent: NoParameterInitializable {
		required init() {}
	}

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

	func testSimple() {
		let container = AutoInitializingContainer(componentStorageFactory: storageFactory)

		XCTAssertNil(container.resolveIfPresent(Int.self))
		XCTAssertEqual(container.resolveIfPresent(String.self), "")

		XCTAssertNotNil(container.resolveIfPresent(NoParameterComponent.self))
		XCTAssertNotNil(container.resolveIfPresent(ResolverComponent.self))
	}

	func testResolvingFromParent() {
		let parentContainer = Container(defaultComponentStorageFactory: storageFactory)
		let childContainer = AutoInitializingContainer(parent: parentContainer, componentStorageFactory: storageFactory)

		parentContainer.register(UnmarkedComponent.self) { UnmarkedComponent() }

		let parentInstance = parentContainer.resolveIfPresent(UnmarkedComponent.self)
		let childInstance = childContainer.resolveIfPresent(UnmarkedComponent.self)
		XCTAssertIdentical(parentInstance, childInstance)
	}

	func testResolvingFromChild() {
		let parentContainer = Container(defaultComponentStorageFactory: storageFactory)
		let childContainer = AutoInitializingContainer(parent: parentContainer, componentStorageFactory: storageFactory)

		XCTAssertNil(parentContainer.resolveIfPresent(NoParameterComponent.self))
		XCTAssertNotNil(childContainer.resolveIfPresent(NoParameterComponent.self))

		XCTAssertNil(parentContainer.resolveIfPresent(ResolverComponent.self))
		XCTAssertNotNil(childContainer.resolveIfPresent(ResolverComponent.self))
	}

	func testValueAndObjectDifferentiation() {
		var weakCounter = 0
		var valueCounter = 0

		let container = AutoInitializingContainer(
			componentStorageFactory: CallbackComponentStorageFactory(
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

		XCTAssertNotNil(container.resolveIfPresent(String.self))
		XCTAssertEqual(weakCounter, 1)
		XCTAssertEqual(valueCounter, 1)

		XCTAssertNotNil(container.resolveIfPresent(NoParameterComponent.self))
		XCTAssertEqual(weakCounter, 2)
		XCTAssertEqual(valueCounter, 1)

		XCTAssertNotNil(container.resolveIfPresent(ResolverComponent.self))
		XCTAssertEqual(weakCounter, 3)
		XCTAssertEqual(valueCounter, 1)
	}
}
