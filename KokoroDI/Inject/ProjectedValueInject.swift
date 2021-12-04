//
//  Created on 04/12/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import KokoroUtils

private let sharedLock: Lock = FoundationLock()

public extension ObjectWith {
	typealias ProjectedValueInject<Component: HasProjectedValue, Variant: Hashable> = AnyProjectedValueInject<Self, Component, Variant>
}

@propertyWrapper
public struct AnyProjectedValueInject<EnclosingSelf, Component: HasProjectedValue, Variant: Hashable> {
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

	@available(*, unavailable, message: "@(Any)Inject can only be applied to classes")
	public var projectedValue: Component.ProjectedValue {
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

	public static subscript(_enclosingInstance observed: EnclosingSelf, projected wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Component.ProjectedValue>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Component.ProjectedValue {
		get {
			var storageValue = observed[keyPath: storageKeyPath]
			return storageValue.lock.acquireAndRun {
				if let component = storageValue.component {
					return component.projectedValue
				} else {
					let resolver = observed[keyPath: storageValue.resolverKeyPath]
					let component = resolver.resolve(for: storageValue.key)
					switch storageValue.resolveMode {
					case .once:
						storageValue.component = component
					case .eachTime:
						break
					}
					return component.projectedValue
				}
			}
		}
		set {
			var storageValue = observed[keyPath: storageKeyPath]
			storageValue.lock.acquireAndRun {
				if storageValue.component == nil {
					let resolver = observed[keyPath: storageValue.resolverKeyPath]
					let component = resolver.resolve(for: storageValue.key)
					switch storageValue.resolveMode {
					case .once:
						storageValue.component = component
					case .eachTime:
						break
					}
				}
				storageValue.component!.projectedValue = newValue
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

public extension AnyProjectedValueInject {
	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, variant: Variant, synchronization: Synchronization = .shared) {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Component.self, variant: variant), synchronization: synchronization)
	}

	init(_ resolverKeyPath: KeyPath<EnclosingSelf, Resolver>, resolve resolveMode: AnyInjectResolveMode = .once, synchronization: Synchronization = .shared) where Variant == VoidComponentKeyVariant {
		self.init(resolverKeyPath, resolve: resolveMode, key: .init(for: Component.self, variant: .shared), synchronization: synchronization)
	}
}

public extension AnyProjectedValueInject where EnclosingSelf: HasResolver {
	init(resolve resolveMode: AnyInjectResolveMode = .once, variant: Variant, synchronization: Synchronization = .shared) {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Component.self, variant: variant), synchronization: synchronization)
	}

	init(resolve resolveMode: AnyInjectResolveMode = .once, synchronization: Synchronization = .shared) where Variant == VoidComponentKeyVariant {
		self.init(\.resolver, resolve: resolveMode, key: .init(for: Component.self, variant: .shared), synchronization: synchronization)
	}
}
#endif
