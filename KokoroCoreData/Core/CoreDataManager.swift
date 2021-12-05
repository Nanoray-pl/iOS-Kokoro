//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(CoreData) && canImport(Foundation)
import Combine
import CoreData
import Foundation
import KokoroUtils

public protocol CoreDataContextProvider {
	/// The context that can be used on a main thread.
	var mainContext: MainThreadCoreDataContext { get }

	/// A context that uses a background queue.
	var backgroundContext: CoreDataContext { get }
}

public protocol CoreDataManager: CoreDataContextProvider {
	associatedtype InitializeOptions
	associatedtype InitializeResult
	associatedtype InitializeFailure: Error

	func initialize(options: InitializeOptions) -> AnyPublisher<InitializeResult, InitializeFailure>
}

public extension DefaultCoreDataManager where ModelVersion: CaseIterable {
	convenience init<ModelProvider>(storeType: DefaultCoreDataManagerStoreType, modelProvider: ModelProvider) where ModelProvider: CoreDataModelProvider, ModelProvider.ModelVersion == ModelVersion {
		self.init(storeType: storeType, modelProvider: modelProvider, migrationPathProvider: CaseIterableCoreDataMigrationPathProvider<ModelVersion>())
	}
}

public enum DefaultCoreDataManagerStoreType {
	case inMemory
	case sqlite(url: URL)
}

public class DefaultCoreDataManager<ModelVersion: CoreDataModelVersion>: CoreDataManager {
	public struct InitializeOptions {
		public enum VersionOverride {
			case latest
			case current
			case specific(_ version: ModelVersion)
		}

		public let versionOverride: VersionOverride
		public let recreate: Bool

		public init(versionOverride: VersionOverride = .latest, recreate: Bool = false) {
			self.versionOverride = versionOverride
			self.recreate = recreate
		}
	}

	public enum InitializeResult {
		case alreadyInitialized(storeType: DefaultCoreDataManagerStoreType)
		case initialized(storeType: DefaultCoreDataManagerStoreType, migrationResult: MigrationResult)
	}

	public enum InitializeFailure: Error {
		case duringInitializing(_ error: Swift.Error)
		case duringDestroying(_ error: Swift.Error)
		case duringMigration(_ error: Swift.Error)
		case duringLoading(_ error: Swift.Error, migrationResult: MigrationResult)

		public enum Error: Swift.Error {
			case stackNotSetup
			case alreadyInitializing
			case cannotRecreateInitializedStack
			case cannotMigrateUnknownVersion
		}
	}

	public enum MigrationResult: Hashable {
		case noStoreToMigrate
		case noMigration(currentVersion: ModelVersion)
		case migrated(migrationPath: [CoreDataMigrationStep<ModelVersion>])

		var currentVersion: ModelVersion {
			switch self {
			case .noStoreToMigrate:
				return .latest
			case let .noMigration(currentVersion):
				return currentVersion
			case let .migrated(migrationPath):
				return migrationPath.last!.destination
			}
		}
	}

	public enum State {
		case awaiting
		case initializing
		case initialized
	}

	public enum PotentialModelVersion: Hashable {
		case none
		case version(_ version: ModelVersion)
		case unknownVersion
	}

	private let storeType: DefaultCoreDataManagerStoreType
	private let modelProvider: AnyCoreDataModelProvider<ModelVersion>
	private let migrationPathProvider: AnyCoreDataMigrationPathProvider<ModelVersion>
	private var stack: (instance: CoreDataStack, version: ModelVersion)?
	public private(set) var state = State.awaiting

	public var mainContext: MainThreadCoreDataContext {
		return stack.unwrap { fatalError("CoreDataStack not initialized yet") }.instance.mainContext
	}

	public var backgroundContext: CoreDataContext {
		return stack.unwrap { fatalError("CoreDataStack not initialized yet") }.instance.backgroundContext
	}

	private lazy var storeDescription: NSPersistentStoreDescription = {
		switch storeType {
		case .inMemory:
			$0.type = NSInMemoryStoreType
			$0.url = nil
		case let .sqlite(url):
			$0.type = NSSQLiteStoreType
			$0.url = url
		}
		$0.shouldInferMappingModelAutomatically = false
		$0.shouldMigrateStoreAutomatically = false
		return $0
	}(NSPersistentStoreDescription())

	public init<ModelProvider, MigrationPathProvider>(storeType: DefaultCoreDataManagerStoreType, modelProvider: ModelProvider, migrationPathProvider: MigrationPathProvider) where ModelProvider: CoreDataModelProvider, MigrationPathProvider: CoreDataMigrationPathProvider, ModelProvider.ModelVersion == ModelVersion, MigrationPathProvider.ModelVersion == ModelVersion {
		self.storeType = storeType
		self.modelProvider = modelProvider.eraseToAnyCoreDataModelProvider()
		self.migrationPathProvider = migrationPathProvider.eraseToAnyCoreDataMigrationPathProvider()
	}

	public func initialize(options: InitializeOptions) -> AnyPublisher<InitializeResult, InitializeFailure> {
		return Deferred { [storeType] () -> AnyPublisher<InitializeResult, InitializeFailure> in
			switch (self.state, recreate: options.recreate) {
			case (.initialized, recreate: false):
				return Just(.alreadyInitialized(storeType: storeType))
					.setFailureType(to: InitializeFailure.self)
					.eraseToAnyPublisher()
			case (.initialized, recreate: true):
				return Fail(error: .duringInitializing(InitializeFailure.Error.cannotRecreateInitializedStack))
					.eraseToAnyPublisher()
			case (.initializing, _):
				return Fail(error: .duringInitializing(InitializeFailure.Error.alreadyInitializing))
					.eraseToAnyPublisher()
			case (.awaiting, _):
				self.state = .initializing

				if options.recreate {
					do {
						try self.destroyStore()
					} catch {
						self.state = .awaiting
						return Fail(error: .duringDestroying(error))
							.eraseToAnyPublisher()
					}
				}

				return self.migrateIfNeeded(versionOverride: options.versionOverride)
					.mapError { .duringMigration($0) }
					.flatMap { migrationResult -> AnyPublisher<InitializeResult, InitializeFailure> in
						do {
							let version: ModelVersion
							switch (migrationResult: migrationResult, versionOverride: options.versionOverride) {
							case let (_, versionOverride: .specific(specificVersion)):
								version = specificVersion
							case (_, _):
								version = migrationResult.currentVersion
							}
							try self.setupStack(for: version)
						} catch {
							return Fail(outputType: InitializeResult.self, failure: .duringLoading(error, migrationResult: migrationResult))
								.eraseToAnyPublisher()
						}
						return self.loadStore()
							.map { .initialized(storeType: storeType, migrationResult: migrationResult) }
							.mapError { .duringLoading($0, migrationResult: migrationResult) }
							.eraseToAnyPublisher()
					}
					.eraseToAnyPublisher()
			}
		}
		.eraseToAnyPublisher()
	}

	public func currentStoreVersion() -> PotentialModelVersion {
		if let stack = stack {
			return .version(stack.version)
		}

		guard let storeUrl = storeDescription.url, FileManager.default.fileExists(atPath: storeUrl.path) else { return .none }
		guard let storeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeDescription.type, at: storeUrl, options: storeDescription.options) else { return .unknownVersion }

		if let version = ModelVersion.allCases.first(where: {
			do {
				let model = try modelProvider.model(for: $0)
				return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: storeMetadata)
			} catch {
				return false
			}
		}) {
			return .version(version)
		}

		return .unknownVersion
	}

	private func migrateIfNeeded(versionOverride: InitializeOptions.VersionOverride) -> AnyPublisher<MigrationResult, Error> {
		return Deferred { () -> AnyPublisher<MigrationResult, Error> in
			let currentPotentialVersion = self.currentStoreVersion()
			switch currentPotentialVersion {
			case .unknownVersion:
				return Fail(error: InitializeFailure.Error.cannotMigrateUnknownVersion)
					.eraseToAnyPublisher()
			case .none:
				return Just(.noStoreToMigrate)
					.setFailureType(to: Error.self)
					.eraseToAnyPublisher()
			case let .version(currentVersion):
				do {
					let migrationPath: [CoreDataMigrationStep<ModelVersion>]
					switch versionOverride {
					case .latest:
						migrationPath = try self.migrationPathProvider.migrationPathToLatestVersion(from: currentVersion)
					case .current:
						migrationPath = []
					case let .specific(destinationVersion):
						migrationPath = try self.migrationPathProvider.migrationPath(from: currentVersion, to: destinationVersion)
					}
					if migrationPath.isEmpty {
						return Just(.noMigration(currentVersion: currentVersion))
							.setFailureType(to: Error.self)
							.eraseToAnyPublisher()
					}

					var currentPublisher = Just(())
						.setFailureType(to: Error.self)
						.eraseToAnyPublisher()

					migrationPath.forEach { step in
						currentPublisher = currentPublisher
							.flatMap { self.migrateStore(from: step.source, to: step.destination) }
							.eraseToAnyPublisher()
					}

					return currentPublisher
						.map { _ in .migrated(migrationPath: migrationPath) }
						.eraseToAnyPublisher()
				} catch {
					return Fail(error: error)
						.eraseToAnyPublisher()
				}
			}
		}
		.eraseToAnyPublisher()
	}

	private func migrateStore(from sourceVersion: ModelVersion, to destinationVersion: ModelVersion) -> AnyPublisher<Void, Error> {
		if sourceVersion == destinationVersion {
			return Just(())
				.setFailureType(to: Error.self)
				.eraseToAnyPublisher()
		}

		return Deferred {
			return Future { promise in
				do {
					let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
					try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
					defer {
						try? FileManager.default.removeItem(at: dir)
					}

					let sourceModel = try self.modelProvider.model(for: sourceVersion)
					let destinationModel = try self.modelProvider.model(for: destinationVersion)
					let mapping = try self.modelProvider.mapping(from: sourceModel, to: destinationModel)
					let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
					let destinationUrl = dir.appendingPathComponent(self.storeDescription.url!.lastPathComponent)
					try autoreleasepool {
						try migrationManager.migrateStore(
							from: self.storeDescription.url!,
							sourceType: self.storeDescription.type,
							options: nil,
							with: mapping,
							toDestinationURL: destinationUrl,
							destinationType: self.storeDescription.type,
							destinationOptions: nil
						)
					}

					let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
					try coordinator.replacePersistentStore(
						at: self.storeDescription.url!,
						destinationOptions: nil,
						withPersistentStoreFrom: destinationUrl,
						sourceOptions: nil,
						ofType: self.storeDescription.type
					)

					promise(.success(()))
				} catch {
					promise(.failure(error))
				}
			}
		}
		.eraseToAnyPublisher()
	}

	private func setupStack(for version: ModelVersion) throws {
		let model = try modelProvider.model(for: version)
		stack = (instance: .init(model: model, storeDescription: storeDescription), version: version)
	}

	private func loadStore() -> AnyPublisher<Void, Error> {
		return Deferred { () -> AnyPublisher<Void, Error> in
			if let stack = self.stack {
				return stack.instance.loadStore()
			} else {
				return Fail(error: InitializeFailure.Error.stackNotSetup)
					.eraseToAnyPublisher()
			}
		}
		.eraseToAnyPublisher()
	}

	private func destroyStore() throws {
		guard let storeUrl = storeDescription.url else { return }
		try autoreleasepool {
			let model = try modelProvider.model(for: ModelVersion.latest)
			let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
			try coordinator.destroyPersistentStore(at: storeUrl, ofType: storeDescription.type, options: storeDescription.options)
			try? FileManager.default.removeItem(at: storeUrl)
		}
	}
}
#endif
