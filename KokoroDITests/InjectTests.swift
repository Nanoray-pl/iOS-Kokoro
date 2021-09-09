//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils
import XCTest
@testable import KokoroDI

class InjectTests: XCTestCase {
	private class Component {}

	private enum TestComponentVariant: ComponentVariant {
		typealias Component = InjectTests.Component

		case first, second
	}

	private class SimpleDependant: ObjectWith, HasResolver {
		let resolver: Resolver
		@Inject() private(set) var component: Component

		init(resolver: Resolver) {
			self.resolver = resolver
		}
	}

	private class VariantDependant: ObjectWith, HasResolver {
		let resolver: Resolver
		@Inject(variant: 1) private(set) var component1: Component
		@Inject(variant: 2) private(set) var component2: Component

		init(resolver: Resolver) {
			self.resolver = resolver
		}
	}

	private class TypedVariantDependant: ObjectWith, HasResolver {
		let resolver: Resolver
		@Inject(TestComponentVariant.first) private(set) var component1: Component
		@Inject(TestComponentVariant.second) private(set) var component2: Component

		init(resolver: Resolver) {
			self.resolver = resolver
		}
	}

	private let storageFactory = LazyComponentStorageFactory.shared

	func testSimple() {
		let container = Container(defaultComponentStorageFactory: storageFactory)
		container.register(Component.self) { Component() }

		let dependant = SimpleDependant(resolver: container)
		_ = dependant.component // this will crash (and fail the test) if there was a problem with DI
	}

	func testVariants() {
		let container = Container(defaultComponentStorageFactory: storageFactory)
		container.register(Component.self, variant: 1) { Component() }
		container.register(Component.self, variant: 2) { Component() }

		let dependant = VariantDependant(resolver: container)
		// these will crash (and fail the test) if there was a problem with DI
		let firstComponent = dependant.component1
		let secondComponent = dependant.component2
		XCTAssertNotIdentical(firstComponent, secondComponent)
	}

	func testTypedVariants() {
		let container = Container(defaultComponentStorageFactory: storageFactory)
		container.register(TestComponentVariant.first) { Component() }
		container.register(TestComponentVariant.second) { Component() }

		let dependant = TypedVariantDependant(resolver: container)
		// these will crash (and fail the test) if there was a problem with DI
		let firstComponent = dependant.component1
		let secondComponent = dependant.component2
		XCTAssertNotIdentical(firstComponent, secondComponent)
	}
}
