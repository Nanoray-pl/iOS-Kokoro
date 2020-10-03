//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public struct CoreDataMigrationStep<ModelVersion: CoreDataModelVersion>: Hashable, CustomStringConvertible {
	public let source: ModelVersion
	public let destination: ModelVersion

	public var description: String {
		return "\(source) -> \(destination)"
	}
}

public protocol CoreDataMigrationPathProvider {
	associatedtype ModelVersion: CoreDataModelVersion

	func next(from version: ModelVersion) -> ModelVersion?
}

public extension CoreDataMigrationPathProvider {
	func eraseToAnyCoreDataMigrationPathProvider() -> AnyCoreDataMigrationPathProvider<ModelVersion> {
		return (self as? AnyCoreDataMigrationPathProvider<ModelVersion>) ?? .init(wrapping: self)
	}
}

public class AnyCoreDataMigrationPathProvider<ModelVersion: CoreDataModelVersion>: CoreDataMigrationPathProvider {
	private let nextClosure: (ModelVersion) -> ModelVersion?

	public init<T>(wrapping wrapped: T) where T: CoreDataMigrationPathProvider, T.ModelVersion == ModelVersion {
		nextClosure = { wrapped.next(from: $0) }
	}

	public func next(from version: ModelVersion) -> ModelVersion? {
		return nextClosure(version)
	}
}

public enum CoreDataMigrationPathProviderError<ModelVersion>: Error {
	case cycleInMigrationPath
	case noMigrationPathBetween(sourceVersion: ModelVersion, destinationVersion: ModelVersion)
}

public extension CoreDataMigrationPathProvider {
	private func internalMigrationPath(from sourceVersion: ModelVersion, to destinationVersion: ModelVersion?) throws -> [CoreDataMigrationStep<ModelVersion>] {
		var steps = [CoreDataMigrationStep<ModelVersion>]()
		var traversed = Set<ModelVersion>()
		var current = sourceVersion

		while current != destinationVersion {
			let insertionResult = traversed.insert(current)
			if !insertionResult.inserted {
				throw CoreDataMigrationPathProviderError<ModelVersion>.cycleInMigrationPath
			}

			if let next = next(from: current) {
				steps.append(.init(source: current, destination: next))
				current = next
			} else if destinationVersion == nil || current == destinationVersion {
				break
			} else {
				throw CoreDataMigrationPathProviderError<ModelVersion>.noMigrationPathBetween(sourceVersion: sourceVersion, destinationVersion: destinationVersion!)
			}
		}
		return steps
	}

	func migrationPath(from sourceVersion: ModelVersion, to destinationVersion: ModelVersion) throws -> [CoreDataMigrationStep<ModelVersion>] {
		return try internalMigrationPath(from: sourceVersion, to: destinationVersion)
	}

	func migrationPathToLatestVersion(from version: ModelVersion) throws -> [CoreDataMigrationStep<ModelVersion>] {
		return try internalMigrationPath(from: version, to: nil)
	}

	func finalVersion(from version: ModelVersion) throws -> ModelVersion {
		return try migrationPathToLatestVersion(from: version).last?.destination ?? version
	}
}

open class CaseIterableCoreDataMigrationPathProvider<ModelVersion>: CoreDataMigrationPathProvider where ModelVersion: CoreDataModelVersion, ModelVersion: CaseIterable {
	open func next(from version: ModelVersion) -> ModelVersion? {
		let index = ModelVersion.allCases.firstIndex(of: version)!
		return index < ModelVersion.allCases.endIndex - 1 ? ModelVersion.allCases[index + 1] : nil
	}
}
