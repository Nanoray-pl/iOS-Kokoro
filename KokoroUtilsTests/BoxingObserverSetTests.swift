//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import XCTest
@testable import KokoroUtils

class BoxingObserverSetTests: XCTestCase {
	private class Observer {
		let closure: () -> Void

		init(closure: @escaping () -> Void) {
			self.closure = closure
		}
	}

	func testAddAndRemove() {
		var counter = 0
		let tested = BoxingObserverSet<Observer, Void>()

		let observer = Observer { counter += 1 }
		tested.insert(observer)
		XCTAssertEqual(counter, 0)

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 1)

		tested.remove(observer)
		XCTAssertEqual(counter, 1)

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 1)
	}

	func testAddAndDeinit() {
		var counter = 0
		let tested = BoxingObserverSet<Observer, Void>()

		autoreleasepool {
			let observer = Observer { counter += 1 }
			tested.insert(observer)
			XCTAssertEqual(counter, 0)

			tested.forEach { $0.closure() }
			XCTAssertEqual(counter, 1)
		}

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 1)
	}

	func testAddTwice() {
		var counter = 0
		let tested = BoxingObserverSet<Observer, Void>()

		let observer = Observer { counter += 1 }
		tested.insert(observer)
		XCTAssertEqual(counter, 0)

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 1)

		tested.insert(observer)
		XCTAssertEqual(counter, 1)

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 2)

		tested.remove(observer)
		XCTAssertEqual(counter, 2)

		tested.forEach { $0.closure() }
		XCTAssertEqual(counter, 2)
	}
}
