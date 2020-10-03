//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import Foundation
import XCTest
@testable import KokoroCoreData

class CoreDataContextTests: XCTestCase {
	private lazy var modelProvider = BundleCoreDataModelProvider<TestModelVersion>(bundle: Bundle.module, name: "TestModel")

	func testInsertion() throws {
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .inMemory, modelProvider: modelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case .success(.initialized(_, migrationResult: .noStoreToMigrate)):
			break
		case let .success(result):
			XCTFail("Expected specific success, but got \(result)")
		case let .failure(error):
			XCTFail("Expected success, but got \(error)")
		}

		do {
			let result = manager.backgroundContext.performPublisher { context in
				let object = TestEntity(context: context)
				object.requiredString = "Test"
				object.optionalString = nil
				object.extraInt = 32
				object.extraDouble = 0.1
				try context.save()
			}
			.subscribe(on: DispatchQueue.global(qos: .background))
			.syncResult()

			switch result {
			case .success:
				break
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let result = manager.backgroundContext.performPublisher { context in
				return try context.fetch(FetchRequest<TestEntity>())
			}
			.subscribe(on: DispatchQueue.global(qos: .background))
			.syncResult()

			switch result {
			case let .success(objects):
				XCTAssertEqual(objects.count, 1)
				let object = try XCTUnwrap(objects.first)
				XCTAssertEqual(object.requiredString, "Test")
				XCTAssertEqual(object.optionalString, nil)
				XCTAssertEqual(object.extraInt, 32)
				XCTAssertEqual(object.extraDouble, 0.1)
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}
	}

	func testDeletion() throws {
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .inMemory, modelProvider: modelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case .success(.initialized(_, migrationResult: .noStoreToMigrate)):
			break
		case let .success(result):
			XCTFail("Expected specific success, but got \(result)")
		case let .failure(error):
			XCTFail("Expected success, but got \(error)")
		}

		do {
			let result = manager.backgroundContext.performPublisher { context in
				let object = TestEntity(context: context)
				object.requiredString = "Test"
				try context.save()
			}
			.subscribe(on: DispatchQueue.global(qos: .background))
			.syncResult()

			switch result {
			case .success:
				break
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let result = manager.backgroundContext.performPublisher { context in
				let results = try context.fetch(FetchRequest<TestEntity>())
				XCTAssertEqual(results.count, 1)

				results.forEach { $0.delete() }
				try context.save()
			}
			.subscribe(on: DispatchQueue.global(qos: .background))
			.syncResult()

			switch result {
			case .success:
				break
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let result = manager.backgroundContext.performPublisher { context in
				return try context.fetch(FetchRequest<TestEntity>())
			}
			.subscribe(on: DispatchQueue.global(qos: .background))
			.syncResult()

			switch result {
			case let .success(objects):
				XCTAssertEqual(objects.count, 0)
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}
	}
}
