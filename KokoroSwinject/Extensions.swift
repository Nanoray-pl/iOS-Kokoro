//
//  Created on 19/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils
import Swinject

extension Container: ObjectWith {
	@discardableResult
	public func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) -> ServiceEntry<Service> {
		return register(serviceType, factory: { _ in factory() })
	}
}
