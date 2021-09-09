//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct UntypedComponentStorage {
	private let componentClosure: () -> Any

	public var component: Any {
		return componentClosure()
	}

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: ComponentStorage {
		componentClosure = { wrapped.component }
	}
}
