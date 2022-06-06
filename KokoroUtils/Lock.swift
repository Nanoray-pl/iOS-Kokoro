//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol Lock {
	func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R
}

public extension Lock {
	func acquireAndRun<T, R>(with input: T, _ closure: (T) throws -> R) rethrows -> R {
		return try acquireAndRun {
			try closure(input)
		}
	}
}

public enum FakeLock: Lock {
	case shared

	public func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R {
		return try closure()
	}
}

public enum Synchronization {
	case none, shared, automatic
	case via(_ lock: Lock)

	public func lock(sharedLock: Lock) -> Lock {
		switch self {
		case .none:
			return FakeLock.shared
		case .shared:
			return sharedLock
		case .automatic:
			return DefaultLock()
		case let .via(lock):
			return lock
		}
	}
}

#if canImport(ObjectiveC)
import ObjectiveC

public class ObjcLock: Lock {
	private let object = NSObject()

	public init() {}

	public func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R {
		objc_sync_enter(object)
		defer { objc_sync_exit(object) }
		return try closure()
	}
}
#endif

#if canImport(Foundation)
import Foundation

public class FoundationLock: Lock {
	private let lock = NSRecursiveLock()

	public init() {}

	public func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R {
		lock.lock()
		defer { lock.unlock() }
		return try closure()
	}
}
#endif

public class PThreadLock: Lock {
	private var mutex = pthread_mutex_t()

	public init() {
		pthread_mutex_init(&mutex, nil)
	}

	public func acquireAndRun<R>(_ closure: () throws -> R) rethrows -> R {
		pthread_mutex_lock(&mutex)
		defer { pthread_mutex_unlock(&mutex) }
		return try closure()
	}
}

#if canImport(Foundation)
public typealias DefaultLock = FoundationLock
#elseif canImport(ObjectiveC)
public typealias DefaultLock = ObjcLock
#else
public typealias DefaultLock = PThreadLock
#endif

@propertyWrapper
public struct AnyLocked<EnclosingSelf, Value, LockType: Lock> {
	private let lockKeyPath: KeyPath<EnclosingSelf, LockType>
	private var value: Value

	@available(*, unavailable, message: "@(Any)Locked can only be applied to classes")
	public var wrappedValue: Value {
		get { fatalError("@(Any)Locked can only be applied to classes") }
		set { fatalError("@(Any)Locked can only be applied to classes") } // swiftlint:disable:this unused_setter_value
	}

	public static subscript(_enclosingInstance observed: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Value {
		get {
			let storageValue = observed[keyPath: storageKeyPath]
			let lock = observed[keyPath: storageValue.lockKeyPath]
			return lock.acquireAndRun { storageValue.value }
		}
		set {
			var storageValue = observed[keyPath: storageKeyPath]
			let lock = observed[keyPath: storageValue.lockKeyPath]
			lock.acquireAndRun { storageValue.value = newValue }
		}
	}

	public init(via lockKeyPath: KeyPath<EnclosingSelf, LockType>) where Value: OptionalConvertible {
		self.value = Value(from: nil)
		self.lockKeyPath = lockKeyPath
	}

	public init(wrappedValue value: Value, via lockKeyPath: KeyPath<EnclosingSelf, LockType>) {
		self.value = value
		self.lockKeyPath = lockKeyPath
	}
}
