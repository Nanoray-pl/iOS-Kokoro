//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import CoreData
import KokoroCoreData

class TestEntity: NSManagedObject, ManagedObject {
	static let entityName = "TestEntity"

	@NSManaged var requiredString: String!
	@NSManaged var optionalString: String?
	@NSManaged var extraInt: Int32
	@NSManaged var extraDouble: Double
}
