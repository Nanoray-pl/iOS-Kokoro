//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

private let sharedLock: Lock = DefaultLock()

public class AutoInitializingContainer {
	private let parent: Resolver?
	private let lock: Lock
	public var componentStorageFactory: ComponentStorageFactory

	private var components = [AnyComponentKey: UntypedComponentStorage]()

	public init(
		parent: Resolver? = nil,
		synchronization: Synchronization = .automatic,
		componentStorageFactory: ComponentStorageFactory
	) {
		self.parent = parent
		self.componentStorageFactory = componentStorageFactory
		lock = synchronization.lock(sharedLock: sharedLock)
	}
}

extension AutoInitializingContainer: Resolver {
	public func resolveIfPresent<Component, Variant: Hashable>(for key: ComponentKey<Component, Variant>) -> Component? {
		return lock.acquireAndRun {
			if let component = components[.init(from: key)]?.component as? Component {
				return component
			}

			if let type = Component.self as? ResolverInitializable.Type {
				let untypedComponentStorage = UntypedComponentStorage(wrapping: componentStorageFactory.createComponentStorage(resolver: self) { type.init(resolver: $0) })
				components[.init(from: key)] = untypedComponentStorage
				return untypedComponentStorage.component as? Component
			}

			if let type = Component.self as? NoParameterInitializable.Type {
				let untypedComponentStorage = UntypedComponentStorage(wrapping: componentStorageFactory.createComponentStorage(resolver: self) { _ in type.init() })
				components[.init(from: key)] = untypedComponentStorage
				return untypedComponentStorage.component as? Component
			}

			return parent?.resolveIfPresent(for: key)
		}
	}
}
