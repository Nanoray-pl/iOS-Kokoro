//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import CoreData
import Foundation
import KokoroUtils
import XCTest
@testable import KokoroCoreData

class PredicateBuilderTests: XCTestCase {
	private lazy var modelProvider = BundleCoreDataModelProvider<TestModelVersion>(bundle: Bundle.module, name: "TestModel")

	private func coreDataContextProvider() -> CoreDataContextProvider {
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .inMemory, modelProvider: modelProvider)
		let result = manager.initialize(options: .init()).syncResult()
		switch result {
		case .success:
			break
		case let .failure(error):
			XCTFail("Expected success, but got \(error)")
		}
		return manager
	}

	private func makeTestValues(context: CoreDataPerformingContext) -> [TestEntity] {
		return [
			TestEntity(context: context).with {
				$0.requiredString = "a"
				$0.extraInt = 0
			},
			TestEntity(context: context).with {
				$0.requiredString = "b"
				$0.extraInt = 1
			},
			TestEntity(context: context).with {
				$0.requiredString = "c"
				$0.extraInt = 2
			},
			TestEntity(context: context).with {
				$0.requiredString = "a"
				$0.extraInt = 3
			},
			TestEntity(context: context).with {
				$0.requiredString = "b"
				$0.extraInt = 4
			},
			TestEntity(context: context).with {
				$0.requiredString = "c"
				$0.extraInt = 5
			},
		]
	}

	func testBoolTruePredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = BoolPredicateBuilder<TestEntity>.true
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "TRUEPREDICATE")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, values)
		}
	}

	func testBoolFalsePredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = BoolPredicateBuilder<TestEntity>.false
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "FALSEPREDICATE")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [])
		}
	}

	func testStringEqualsB() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.requiredString == "b"
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "requiredString == \"b\"")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[1], values[4]])
		}
	}

	func testStringNotEqualsC() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.requiredString != "c"
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "requiredString != \"c\"")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[0], values[1], values[3], values[4]])
		}
	}

	func testIntEquals3() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.extraInt == 3
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt == 3")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[3]])
		}
	}

	func testIntLessThan3() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.extraInt < 3
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt < 3")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[0], values[1], values[2]])
		}
	}

	func testIntGreaterThan4() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.extraInt > 4
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt > 4")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[5]])
		}
	}

	func testIntLessThanOrEqual1() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.extraInt <= 1
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt <= 1")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[0], values[1]])
		}
	}

	func testIntGreaterThanOrEqual4() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = \TestEntity.extraInt >= 4
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt >= 4")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[4], values[5]])
		}
	}

	func testRawPredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = RawPredicateBuilder<TestEntity>(format: "extraInt BETWEEN {%@, %@}", 1, 3)
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt BETWEEN {1, 3}")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[1], values[2], values[3]])
		}
	}

	func testNotPredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = !RawPredicateBuilder<TestEntity>(format: "extraInt BETWEEN {%@, %@}", 1, 3)
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "NOT extraInt BETWEEN {1, 3}")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[0], values[4], values[5]])
		}
	}

	func testOrPredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder1 = \TestEntity.extraInt == 1
			do {
				let predicate = builder1.build()
				XCTAssertEqual(predicate.predicateFormat, "extraInt == 1")

				let filtered = values.filter { predicate.evaluate(with: $0) }
				XCTAssertEqual(filtered, [values[1]])
			}

			let builder2 = \TestEntity.requiredString == "a"
			do {
				let predicate = builder2.build()
				XCTAssertEqual(predicate.predicateFormat, "requiredString == \"a\"")

				let filtered = values.filter { predicate.evaluate(with: $0) }
				XCTAssertEqual(filtered, [values[0], values[3]])
			}

			let builder = builder1 || builder2
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt == 1 OR requiredString == \"a\"")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[0], values[1], values[3]])
		}
	}

	func testAndPredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder1 = RawPredicateBuilder<TestEntity>(format: "extraInt BETWEEN {%@, %@}", 1, 3)
			do {
				let predicate = builder1.build()
				XCTAssertEqual(predicate.predicateFormat, "extraInt BETWEEN {1, 3}")

				let filtered = values.filter { predicate.evaluate(with: $0) }
				XCTAssertEqual(filtered, [values[1], values[2], values[3]])
			}

			let builder2 = \TestEntity.requiredString == "a"
			do {
				let predicate = builder2.build()
				XCTAssertEqual(predicate.predicateFormat, "requiredString == \"a\"")

				let filtered = values.filter { predicate.evaluate(with: $0) }
				XCTAssertEqual(filtered, [values[0], values[3]])
			}

			let builder = builder1 && builder2
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "extraInt BETWEEN {1, 3} AND requiredString == \"a\"")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[3]])
		}
	}

	func testComplexPredicate() {
		let context = coreDataContextProvider().backgroundContext
		context.performAndWait { context in
			let values = self.makeTestValues(context: context)

			let builder = (\TestEntity.requiredString == "a" || \TestEntity.requiredString == "b") && (\TestEntity.extraInt == 1 || \TestEntity.extraInt == 999)
			let predicate = builder.build()
			XCTAssertEqual(predicate.predicateFormat, "(requiredString == \"a\" OR requiredString == \"b\") AND (extraInt == 1 OR extraInt == 999)")

			let filtered = values.filter { predicate.evaluate(with: $0) }
			XCTAssertEqual(filtered, [values[1]])
		}
	}
}
