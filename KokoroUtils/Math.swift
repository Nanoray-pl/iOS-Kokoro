//
//  Created on 19/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public extension Measurement {
	static prefix func - (value: Measurement<UnitType>) -> Measurement<UnitType> {
		return Measurement(value: -value.value, unit: value.unit)
	}
}
#endif
