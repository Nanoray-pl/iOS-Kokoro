//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import KokoroUtils

private let sharedLock: Lock = FoundationLock()

private enum WeakComponentStorageLock: Lock {
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

public class WeakComponentStorage<Component>: ComponentStorage {
	private enum ValueStorage {
		case factory(_ factory: ComponentStorageFactory)
		case storage(_ storage: AnyComponentStorage<Component>)
	}

	private unowned let resolver: Resolver
	private let lock: Lock
	private let factory: (Resolver) -> Component

	private weak var componentStorage: AnyObject?
	private var valueStorage: ValueStorage

	public var component: Component {
		return lock.acquireAndRun {
			if let component = componentStorage {
				return component as! Component
			} else {
				switch valueStorage {
				case let .storage(storage):
					return storage.component
				case .factory:
					break
				}

				let component = factory(resolver)
				if type(of: component as Any) is AnyClass {
					componentStorage = component as AnyObject
				} else {
					switch valueStorage {
					case let .factory(factory):
						valueStorage = .storage(factory.createComponentStorage(resolver: resolver, with: component, factory: self.factory))
					case .storage:
						fatalError("This should not happen")
					}
				}
				return component
			}
		}
	}

	public init(resolver: Resolver, valueStorageFactory: ComponentStorageFactory, synchronization: Synchronization = .shared, component: Component, factory: @escaping (Resolver) -> Component) {
		self.resolver = resolver
		self.factory = factory
		lock = synchronization.lock(sharedLock: sharedLock)

		if type(of: component) is AnyClass {
			valueStorage = .factory(valueStorageFactory)
			componentStorage = component as AnyObject
		} else {
			valueStorage = .storage(valueStorageFactory.createComponentStorage(resolver: resolver, with: component, factory: factory))
		}
	}

	public init(resolver: Resolver, valueStorageFactory: ComponentStorageFactory, synchronization: Synchronization = .shared, factory: @escaping (Resolver) -> Component) {
		self.resolver = resolver
		valueStorage = .factory(valueStorageFactory)
		self.factory = factory
		lock = synchronization.lock(sharedLock: sharedLock)
	}
}

public struct WeakComponentStorageFactory: ComponentStorageFactory {
	private let valueStorageFactory: ComponentStorageFactory
	private let synchronizationProvider: (Any.Type) -> Synchronization

	public init(valueStorageFactory: ComponentStorageFactory, synchronization synchronizationProvider: @escaping (Any.Type) -> Synchronization) {
		self.valueStorageFactory = valueStorageFactory
		self.synchronizationProvider = synchronizationProvider
	}

	public init(valueStorageFactory: ComponentStorageFactory, synchronization: Synchronization = .shared) {
		self.init(valueStorageFactory: valueStorageFactory) { _ in synchronization }
	}

	public func createComponentStorage<Component>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
		return WeakComponentStorage(resolver: resolver, valueStorageFactory: valueStorageFactory, synchronization: synchronizationProvider(Component.self), factory: factory)
			.eraseToAnyComponentStorage()
	}

	public func createComponentStorage<Component>(resolver: Resolver, with component: Component, factory: @escaping (Resolver) -> Component) -> AnyComponentStorage<Component> {
		return WeakComponentStorage(resolver: resolver, valueStorageFactory: valueStorageFactory, synchronization: synchronizationProvider(Component.self), component: component, factory: factory)
			.eraseToAnyComponentStorage()
	}
}
#endif
