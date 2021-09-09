//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol Resolver: ObjectWith {
	func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component?
	func resolve<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component
}

public extension Resolver {
	func resolve<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component {
		return resolveIfPresent(for: key)!
	}

	func resolveIfPresent<Component, Variant: Hashable>(_ componentType: Component.Type, variant: Variant) -> Component? {
		return resolveIfPresent(for: .init(for: componentType, variant: variant))
	}

	func resolve<Component, Variant: Hashable>(_ componentType: Component.Type, variant: Variant) -> Component {
		return resolve(for: .init(for: componentType, variant: variant))
	}

	func resolveIfPresent<Component>(_ componentType: Component.Type) -> Component? {
		return resolveIfPresent(componentType, variant: VoidComponentKeyVariant.shared)
	}

	func resolve<Component>(_ componentType: Component.Type) -> Component {
		return resolve(componentType, variant: VoidComponentKeyVariant.shared)
	}
}
