//
//  Created on 21/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public enum LateInitSynchronization {
	case none, shared, automatic
	case via(_ lock: Lock)
}

private enum LateInitSynchronizationLock: Lock {
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

private let sharedLock: Lock = DefaultLock()

@propertyWrapper
public struct LateInit<T> {
	private enum State {
		case uninitialized
		case initialized(_ value: T)
	}

	private let lock: LateInitSynchronizationLock
	private var state = State.uninitialized

	public var isInitialized: Bool {
		return lock.acquireAndRun {
			switch state {
			case .uninitialized:
				return false
			case .initialized:
				return true
			}
		}
	}

	public var wrappedValue: T {
		get {
			return lock.acquireAndRun {
				switch state {
				case .uninitialized:
					fatalError("@LateInit is not yet initialized.")
				case let .initialized(value):
					return value
				}
			}
		}
		set {
			lock.acquireAndRun {
				switch state {
				case .uninitialized:
					state = .initialized(newValue)
				case .initialized:
					fatalError("@LateInit is already initialized.")
				}
			}
		}
	}

	public var projectedValue: Self {
		return self
	}

	public init(synchronization: LateInitSynchronization = .shared) {
		switch synchronization {
		case .none:
			lock = .none
		case .shared:
			lock = .via(sharedLock)
		case .automatic:
			lock = .via(DefaultLock())
		case let .via(lock):
			self.lock = .via(lock)
		}
	}
}
