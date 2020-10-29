//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import Foundation
import XCTest
@testable import KokoroCoreData

class CoreDataManagerTests: XCTestCase {
	private lazy var modelProvider = BundleCoreDataModelProvider<TestModelVersion>(bundle: Bundle.module, name: "TestModel")
	private lazy var missingModelProvider = BundleCoreDataModelProvider<TestModelVersion>(bundle: Bundle.module, name: "MissingModel")

	func testInMemoryInitialization() {
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .inMemory, modelProvider: modelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case .success(.initialized(_, migrationResult: .noStoreToMigrate)):
			XCTAssertEqual(manager.currentStoreVersion(), .version(.latest))
		case let .success(result):
			XCTFail("Expected specific success, but got \(result)")
		case let .failure(error):
			XCTFail("Expected success, but got \(error)")
		}
	}

	func testSqliteInitialization() {
		let storeUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString).sqlite")
		defer { try? FileManager.default.removeItem(at: storeUrl) }
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: modelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case .success(.initialized(_, migrationResult: .noStoreToMigrate)):
			XCTAssertEqual(manager.currentStoreVersion(), .version(.latest))
		case let .success(result):
			XCTFail("Expected specific success, but got \(result)")
		case let .failure(error):
			XCTFail("Expected success, but got \(error)")
		}
	}

	func testMigration() {
		let storeUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString).sqlite")
		defer { try? FileManager.default.removeItem(at: storeUrl) }

		do {
			let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: modelProvider)
			XCTAssertEqual(manager.currentStoreVersion(), .none)
			let result = manager.initialize(options: .init(versionOverride: .specific(.model))).syncResult()

			switch result {
			case .success(.initialized(_, migrationResult: .noStoreToMigrate)):
				XCTAssertEqual(manager.currentStoreVersion(), .version(.model))
			case let .success(result):
				XCTFail("Expected specific success, but got \(result)")
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: modelProvider)
			let result = manager.initialize(options: .init(versionOverride: .current)).syncResult()

			switch result {
			case .success(.initialized(_, migrationResult: .noMigration(currentVersion: .model))):
				XCTAssertEqual(manager.currentStoreVersion(), .version(.model))
			case let .success(result):
				XCTFail("Expected specific success, but got \(result)")
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: modelProvider)
			let result = manager.initialize(options: .init(versionOverride: .latest)).syncResult()

			switch result {
			case .success(.initialized(_, migrationResult: .migrated)):
				XCTAssertEqual(manager.currentStoreVersion(), .version(.latest))
			case let .success(result):
				XCTFail("Expected specific success, but got \(result)")
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}

		do {
			let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: modelProvider)
			let result = manager.initialize(options: .init(versionOverride: .latest)).syncResult()

			switch result {
			case .success(.initialized(_, migrationResult: .noMigration(currentVersion: .latest))):
				XCTAssertEqual(manager.currentStoreVersion(), .version(.latest))
			case let .success(result):
				XCTFail("Expected specific success, but got \(result)")
			case let .failure(error):
				XCTFail("Expected success, but got \(error)")
			}
		}
	}

	func testMissingModel() {
		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .inMemory, modelProvider: missingModelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case let .success(result):
			XCTFail("Expected failure, but got \(result)")
		case .failure(.duringLoading(BundleCoreDataModelProviderError<TestModelVersion>.cannotFind, migrationResult: .noStoreToMigrate)):
			break
		case let .failure(error):
			XCTFail("Expected specific failure, but got \(error)")
		}
	}

	func testDamagedStore() {
		let storeUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString).sqlite")
		defer { try? FileManager.default.removeItem(at: storeUrl) }
		try! UUID().uuidString.write(to: storeUrl, atomically: true, encoding: .utf8)

		let manager = DefaultCoreDataManager<TestModelVersion>(storeType: .sqlite(url: storeUrl), modelProvider: missingModelProvider)
		let result = manager.initialize(options: .init()).syncResult()

		switch result {
		case let .success(result):
			XCTFail("Expected failure, but got \(result)")
		case .failure(.duringMigration(DefaultCoreDataManager<TestModelVersion>.InitializeFailure.Error.cannotMigrateUnknownVersion)):
			break
		case let .failure(error):
			XCTFail("Expected specific failure, but got \(error)")
		}
	}
}
