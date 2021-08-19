//
//  Created on 19/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils
import Swinject

public protocol ServiceVariant {
	associatedtype Service

	var variantName: String { get }
}

public extension ServiceVariant where Self: RawRepresentable, RawValue == String {
	var variantName: String {
		return rawValue
	}
}

public protocol VoidServiceVariantProtocol {
	static var instance: Self { get }
}

public enum VoidServiceVariant<Service>: ServiceVariant, VoidServiceVariantProtocol {
	case instance

	public var variantName: String {
		return ""
	}
}

public extension Container {
	@discardableResult
	func register<Variant: ServiceVariant>(_ variant: Variant, factory: @escaping () -> Variant.Service) -> ServiceEntry<Variant.Service> {
		return register(Variant.Service.self, name: variant.variantName) { _ in factory() }
	}

	@discardableResult
	func register<Variant: ServiceVariant>(_ variant: Variant, factory: @escaping (Resolver) -> Variant.Service) -> ServiceEntry<Variant.Service> {
		return register(Variant.Service.self, name: variant.variantName, factory: factory)
	}
}

public extension Resolver {
	func resolve<Variant: ServiceVariant>(_ variant: Variant) -> Variant.Service? {
		return resolve(Variant.Service.self, name: variant.variantName)
	}
}
