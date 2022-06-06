//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

private let sharedLock: Lock = DefaultLock()

public extension ObjectWith {
	typealias Inject<Component, Variant: Hashable> = AnyInject<Self, Component, Variant>
}

public protocol HasResolver {
	var resolver: Resolver { get }
}

public enum AnyInjectResolveMode {
	case once, eachTime
}

@propertyWrapper
public struct AnyInject<EnclosingSelf, Component, Variant: Hashable> {
	private let resolverKeyPath: KeyPath<EnclosingSelf, Resolver>
	private let resolveMode: AnyInjectResolveMode
	private let key: ComponentKey<Component, Variant>
	private let lock: Lock
	private var component: Component!

	@available(*, unavailable, message: "@(Any)Inject can only be applied to classes")
	public var wrappedValue: Component {
		get { fatalError("@(Any)Inject can only be applied to classes") }
		set { fatalError("@(Any)Inject can only be applied to classes") } // swiftlint:disable:this unused_setter_value
	}

	public static subscript(_enclosingInstance observed: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Component>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Component {
		get {
			var storageValue = observed[keyPath: storageKeyPath]
			return storageValue.lock.acquireAndRun {
				if let component = storageValue.component {
					return component
				} else {
					let resolver = observed[keyPath: storageValue.resolverKeyPath]
					let component = resolver.resolve(for: storageValue.key)
					switch storageValue.resolveMode {
					case .once:
						storageValue.component = component
					case .eachTime:
						break
					}
					return component
				}
			}
		}
		set {
			var storageValue = observed[keyPath: storageKeyPath]
			storageValue.lock.acquireAndRun {
				storageValue.component = newValue
			}
		}
	}

	public init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, key: ComponentKey<Component, Variant>, synchronization: Synchronization = .shared) {
		self.resolverKeyPath = resolverKeyPath
		self.resolveMode = resolveMode
		self.key = key
		lock = synchronization.lock(sharedLock: sharedLock)
	}
}

public extension AnyInject {
	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, variant: Variant, synchronization: Synchronization = .shared) {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Component.self, variant: variant), synchronization: synchronization)
	}

	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, synchronization: Synchronization = .shared) where Variant == VoidComponentKeyVariant {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Component.self, variant: .shared), synchronization: synchronization)
	}
}

public extension AnyInject where EnclosingSelf: HasResolver {
	init(resolve resolveMode: AnyInjectResolveMode = .once, variant: Variant, synchronization: Synchronization = .shared) {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Component.self, variant: variant), synchronization: synchronization)
	}

	init(resolve resolveMode: AnyInjectResolveMode = .once, synchronization: Synchronization = .shared) where Variant == VoidComponentKeyVariant {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Component.self, variant: .shared), synchronization: synchronization)
	}
}
