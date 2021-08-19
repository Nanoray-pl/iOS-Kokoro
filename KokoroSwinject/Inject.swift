//
//  Created on 19/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import KokoroUtils
import Swinject

public extension ObjectWith {
	typealias Inject<T> = AnyInject<Self, VoidServiceVariant<T>>
	typealias InjectVariant<Variant: ServiceVariant> = AnyInject<Self, Variant>
}

public enum AnyInjectSynchronization {
	case none, shared, automatic
	case via(_ lock: Lock)
}

private enum AnyInjectSynchronizationLock: Lock {
	case none
	case via(_ lock: Lock)

	func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R {
		switch self {
		case .none:
			return try closure()
		case let .via(lock):
			return try lock.acquireAndRun(closure)
		}
	}
}

private let sharedLock: Lock = FoundationLock()

@propertyWrapper
public struct AnyInject<EnclosingSelf, Variant: ServiceVariant> {
	private let resolverKeyPath: KeyPath<EnclosingSelf, Resolver>
	private let variant: Variant
	private let lock: AnyInjectSynchronizationLock
	private var component: Variant.Service!

	@available(*, unavailable, message: "@(Any)Inject can only be applied to classes")
	public var wrappedValue: Variant.Service {
		get { fatalError("@(Any)Inject can only be applied to classes") }
		set { fatalError("@(Any)Inject can only be applied to classes") } // swiftlint:disable:this unused_setter_value
	}

	public static subscript(_enclosingInstance observed: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Variant.Service>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Variant.Service {
		var storageValue = observed[keyPath: storageKeyPath]
		return storageValue.lock.acquireAndRun {
			if let component = storageValue.component {
				return component
			} else {
				let resolver = observed[keyPath: storageValue.resolverKeyPath]
				let component: Variant.Service
				if storageValue.variant is VoidServiceVariantProtocol {
					component = resolver.resolve(Variant.Service.self)!
				} else {
					component = resolver.resolve(storageValue.variant)!
				}
				storageValue.component = component
				return component
			}
		}
	}

	public init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, variant: Variant, synchronization: AnyInjectSynchronization = .shared) {
		self.resolverKeyPath = resolverKeyPath
		self.variant = variant
		switch synchronization {
		case .none:
			lock = .none
		case .shared:
			lock = .via(sharedLock)
		case .automatic:
			lock = .via(FoundationLock())
		case let .via(lock):
			self.lock = .via(lock)
		}
	}

	public init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, synchronization: AnyInjectSynchronization = .shared) where Variant: VoidServiceVariantProtocol {
		self.init(resolverKeyPath, variant: Variant.instance, synchronization: synchronization)
	}
}
#endif
