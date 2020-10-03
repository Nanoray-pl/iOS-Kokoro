//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(CoreData) && canImport(Foundation)
import Combine
import CoreData
import Foundation

public class CoreDataStack {
	public enum State {
		case awaiting
		case loading
		case loaded
	}

	public enum StateError: Error {
		case alreadyLoading
	}

	private let model: NSManagedObjectModel
	private let storeDescription: NSPersistentStoreDescription
	public private(set) lazy var coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
	public private(set) var state = State.awaiting

	public private(set) lazy var mainContext: MainThreadCoreDataContext = {
		$0.persistentStoreCoordinator = coordinator
		$0.automaticallyMergesChangesFromParent = true
		return MainThreadCoreDataContext(wrapping: $0)
	}(NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))

	public private(set) lazy var backgroundContext: CoreDataContext = {
		$0.persistentStoreCoordinator = coordinator
		$0.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return CoreDataContext(wrapping: $0)
	}(NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType))

	public init(model: NSManagedObjectModel, storeDescription: NSPersistentStoreDescription) {
		self.model = model
		self.storeDescription = storeDescription
	}

	public func loadStore() -> AnyPublisher<Void, Error> {
		return Deferred {
			return Future { promise in
				switch self.state {
				case .loaded:
					promise(.success(()))
				case .loading:
					promise(.failure(StateError.alreadyLoading))
				case .awaiting:
					self.state = .loading
					self.coordinator.addPersistentStore(with: self.storeDescription) { _, error in
						if let error = error {
							promise(.failure(error))
						} else {
							self.state = .loaded
							promise(.success(()))
						}
					}
				}
			}
		}
		.eraseToAnyPublisher()
	}
}
#endif
