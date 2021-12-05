//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroDI

class WeakComponentStorageTests: XCTestCase {
	private class BlankResolver: Resolver {
		func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component? {
			return nil
		}
	}

	private class Component {
		private static var nextValue = 0
		let value: Int

		init() {
			value = Self.nextValue
			Self.nextValue += 1
		}
	}

	func test() {
		let storageFactory = WeakComponentStorageFactory(valueStorageFactory: LazyComponentStorageFactory.shared)
		let resolver = BlankResolver()
		let storage = storageFactory.createComponentStorage(resolver: resolver) { _ in Component() }

		var instance: Component! = storage.component
		let firstValue = instance.value
		instance = storage.component
		let secondValue = instance.value
		XCTAssertEqual(firstValue, secondValue)

		instance = nil
		instance = storage.component
		let thirdValue = instance.value
		XCTAssertNotEqual(thirdValue, firstValue)
	}
}
