//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol Lock {
	func acquireAndRun<T>(_ closure: () throws -> T) rethrows -> T
}

#if canImport(ObjectiveC)
import ObjectiveC

public class ObjcLock: Lock {
	private let object = NSObject()

	public init() {}

	public func acquireAndRun<T>(_ closure: () throws -> T) rethrows -> T {
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

	public func acquireAndRun<T>(_ closure: () throws -> T) rethrows -> T {
		lock.lock()
		defer { lock.unlock() }
		return try closure()
	}
}
#endif
