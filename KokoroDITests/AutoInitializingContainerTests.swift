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
		var valueCounter = 0
		var objectCounter = 0

		let container = AutoInitializingContainer(
			componentStorageFactory: TestStorageFactory(
				wrapping: storageFactory,
				valueClosure: { valueCounter += 1 },
				objectClosure: { objectCounter += 1 }
			)
		)

		XCTAssertEqual(valueCounter, 0)
		XCTAssertEqual(objectCounter, 0)

		XCTAssertNotNil(container.resolveIfPresent(String.self))
		XCTAssertEqual(valueCounter, 1)
		XCTAssertEqual(objectCounter, 0)

		XCTAssertNotNil(container.resolveIfPresent(NoParameterComponent.self))
		XCTAssertEqual(valueCounter, 1)
		XCTAssertEqual(objectCounter, 1)

		XCTAssertNotNil(container.resolveIfPresent(ResolverComponent.self))
		XCTAssertEqual(valueCounter, 1)
		XCTAssertEqual(objectCounter, 2)
	}
}
