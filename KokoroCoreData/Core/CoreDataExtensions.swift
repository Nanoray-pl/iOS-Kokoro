//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData)
import CoreData

public extension NSManagedObject {
	func delete() {
		managedObjectContext?.delete(self)
	}

	func turnIntoFault() {
		managedObjectContext?.refresh(self, mergeChanges: false)
	}
}

public extension NSOrderedSet {
	func allObjects<T>() -> [T] {
		var results = [T]()
		enumerateObjects { object, _, _ in
			if let castedObject = object as? T {
				results.append(castedObject)
			}
		}
		return results
	}
}
#endif
