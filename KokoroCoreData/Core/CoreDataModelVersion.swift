//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol CoreDataModelVersion: Hashable {
	/// All known model versions.
	static var allCases: [Self] { get }

	/// The latest model version, as in, the model version that should be used by default if there is no persistent store present yet.
	/// - Warning: This may or may not be the version that will be used after migrating a persistent store, as migrations are controlled by the `CoreDataManager` (and in turn by a `CoreDataMigrationPathProvider` for the `DefaultCoreDataManager`).
	static var latest: Self { get }
}

public extension CoreDataModelVersion {
	static var latest: Self {
		return allCases.last!
	}
}
