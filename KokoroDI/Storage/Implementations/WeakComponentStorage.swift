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

public class WeakComponentStorage<Component: AnyObject>: ObjectComponentStorage {
	private unowned let resolver: Resolver
	private let lock: Lock
	private let factory: (Resolver) -> Component

	private weak var componentStorage: Component?

	public var component: Component {
		return lock.acquireAndRun {
			if let component = componentStorage {
				return component
			} else {
				let component = factory(resolver)
				componentStorage = component
				return component
			}
		}
	}

	public init(resolver: Resolver, synchronization: Synchronization = .shared, factory: @escaping (Resolver) -> Component) {
		self.resolver = resolver
		self.factory = factory
		lock = synchronization.lock(sharedLock: sharedLock)
	}
}

public struct WeakComponentStorageFactory: ObjectComponentStorageFactory {
	private let synchronizationProvider: (Any.Type) -> Synchronization

	public init(synchronization synchronizationProvider: @escaping (Any.Type) -> Synchronization) {
		self.synchronizationProvider = synchronizationProvider
	}

	public init(synchronization: Synchronization = .shared) {
		self.init { _ in synchronization }
	}

	public func createObjectComponentStorage<Component: AnyObject>(resolver: Resolver, factory: @escaping (Resolver) -> Component) -> AnyObjectComponentStorage<Component> {
		return WeakComponentStorage(resolver: resolver, synchronization: synchronizationProvider(Component.self), factory: factory)
			.eraseToAnyObjectComponentStorage()
	}
}
#endif
