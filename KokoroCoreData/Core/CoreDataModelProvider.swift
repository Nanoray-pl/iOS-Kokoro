//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

public protocol CoreDataModelProvider {
	associatedtype ModelVersion: CoreDataModelVersion

	func model(for version: ModelVersion) throws -> NSManagedObjectModel
	func mapping(from sourceModel: NSManagedObjectModel, to destinationModel: NSManagedObjectModel) throws -> NSMappingModel
}

public extension CoreDataModelProvider {
	func eraseToAnyCoreDataModelProvider() -> AnyCoreDataModelProvider<ModelVersion> {
		return (self as? AnyCoreDataModelProvider<ModelVersion>) ?? .init(wrapping: self)
	}
}

public class AnyCoreDataModelProvider<ModelVersion: CoreDataModelVersion>: CoreDataModelProvider {
	private let modelClosure: (ModelVersion) throws -> NSManagedObjectModel
	private let mappingClosure: (NSManagedObjectModel, NSManagedObjectModel) throws -> NSMappingModel

	public init<T>(wrapping wrapped: T) where T: CoreDataModelProvider, T.ModelVersion == ModelVersion {
		modelClosure = { try wrapped.model(for: $0) }
		mappingClosure = { try wrapped.mapping(from: $0, to: $1) }
	}

	public func model(for version: ModelVersion) throws -> NSManagedObjectModel {
		return try modelClosure(version)
	}

	public func mapping(from sourceModel: NSManagedObjectModel, to destinationModel: NSManagedObjectModel) throws -> NSMappingModel {
		return try mappingClosure(sourceModel, destinationModel)
	}
}

public protocol BundleCoreDataModelResolver {
	associatedtype ModelVersion: CoreDataModelVersion

	func fileNameInBundle(for version: ModelVersion) -> String
}

public enum BundleCoreDataModelProviderError<ModelVersion: CoreDataModelVersion>: Swift.Error {
	case cannotFind(version: ModelVersion)
	case cannotLoad(version: ModelVersion)
}

public class BundleCoreDataModelProvider<ModelVersion: CoreDataModelVersion>: CoreDataModelProvider {
	private let bundle: Bundle
	private let name: String
	private let fileNameInBundleForVersionClosure: (ModelVersion) -> String

	public init<Resolver>(bundle: Bundle, name: String, resolver: Resolver) where Resolver: BundleCoreDataModelResolver, Resolver.ModelVersion == ModelVersion {
		self.bundle = bundle
		self.name = name
		fileNameInBundleForVersionClosure = { resolver.fileNameInBundle(for: $0) }
	}

	public func model(for version: ModelVersion) throws -> NSManagedObjectModel {
		let subdirectory = "\(name).momd"
		let fileName = fileNameInBundleForVersionClosure(version)
		let omoUrl = bundle.url(forResource: fileName, withExtension: "omo", subdirectory: subdirectory)
		let momUrl = bundle.url(forResource: fileName, withExtension: "mom", subdirectory: subdirectory)

		guard let url = omoUrl ?? momUrl else {
			throw BundleCoreDataModelProviderError<ModelVersion>.cannotFind(version: version)
		}
		guard let model = NSManagedObjectModel(contentsOf: url) else {
			throw BundleCoreDataModelProviderError<ModelVersion>.cannotLoad(version: version)
		}
		return model
	}

	public func mapping(from sourceModel: NSManagedObjectModel, to destinationModel: NSManagedObjectModel) throws -> NSMappingModel {
		if let mapping = NSMappingModel(from: [bundle], forSourceModel: sourceModel, destinationModel: destinationModel) {
			return mapping
		} else {
			return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
		}
	}
}

public protocol CoreDataModelVersionWithFileName: CoreDataModelVersion {
	var fileName: String { get }
}

public extension CoreDataModelVersionWithFileName where Self: RawRepresentable, RawValue == String {
	var fileName: String {
		return rawValue
	}
}

public class BundleFileNameCoreDataModelResolver<ModelVersion: CoreDataModelVersionWithFileName>: BundleCoreDataModelResolver {
	public func fileNameInBundle(for version: ModelVersion) -> String {
		return version.fileName
	}
}

public extension BundleCoreDataModelProvider where ModelVersion: CoreDataModelVersionWithFileName {
	convenience init(bundle: Bundle, name: String) {
		self.init(bundle: bundle, name: name, resolver: BundleFileNameCoreDataModelResolver<ModelVersion>())
	}
}
#endif
