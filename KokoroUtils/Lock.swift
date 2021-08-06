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
