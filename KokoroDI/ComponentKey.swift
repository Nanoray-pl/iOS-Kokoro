//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public enum VoidComponentKeyVariant: Hashable {
	case shared
}

public struct ComponentKey<Component, Variant: Hashable>: Hashable {
	public let type: Component.Type
	public let variant: Variant

	public init(for type: Component.Type, variant: Variant) {
		self.type = type
		self.variant = variant
	}

	public static func == (lhs: ComponentKey<Component, Variant>, rhs: ComponentKey<Component, Variant>) -> Bool {
		return lhs.type == rhs.type && lhs.variant == rhs.variant
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(type))
		hasher.combine(variant)
	}
}

public extension ComponentKey where Variant == VoidComponentKeyVariant {
	init(for type: Component.Type) {
		self.init(for: type, variant: .shared)
	}
}

public struct AnyComponentKey: Hashable {
	private let componentKeyHashable: AnyHashable

	public init<Component, Variant: Hashable>(from componentKey: ComponentKey<Component, Variant>) {
		componentKeyHashable = .init(componentKey)
	}
}
