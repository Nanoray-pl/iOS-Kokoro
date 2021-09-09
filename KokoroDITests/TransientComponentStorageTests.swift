//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroDI

class TransientComponentStorageTests: XCTestCase {
	private class Component {}

	private class BlankResolver: Resolver {
		func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component? {
			return nil
		}
	}

	func test() {
		let storageFactory = TransientComponentStorageFactory.shared
		let resolver = BlankResolver()
		let storage = storageFactory.createComponentStorage(resolver: resolver) { _ in Component() }

		let firstInstance = storage.component
		let secondInstance = storage.component
		XCTAssertNotIdentical(firstInstance, secondInstance)
	}
}
