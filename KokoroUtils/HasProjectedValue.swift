//
//  Created on 04/12/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public protocol HasReadOnlyProjectedValue {
	associatedtype ProjectedValue

	var projectedValue: ProjectedValue { get }
}

public protocol HasProjectedValue: HasReadOnlyProjectedValue {
	var projectedValue: ProjectedValue { get set }
}
