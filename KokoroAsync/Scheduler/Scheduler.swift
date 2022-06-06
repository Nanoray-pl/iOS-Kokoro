//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public protocol Executor {
	func execute(_ workItem: DispatchWorkItem)
}

public extension Executor {
	func execute(_ closure: @escaping () -> Void) {
		let workItem = DispatchWorkItem(block: closure)
		execute(workItem)
	}
}

public enum SynchronousExecutor: Executor {
	case shared

	public func execute(_ workItem: DispatchWorkItem) {
		if !workItem.isCancelled {
			workItem.perform()
		}
	}
}

public protocol Scheduler: Executor {
	var currentDate: Date { get }

	func schedule(at date: Date, execute workItem: DispatchWorkItem)
	func schedule(after delay: TimeInterval, execute workItem: DispatchWorkItem)
}

public extension Scheduler {
	@discardableResult
	func schedule(after delay: TimeInterval, execute closure: @escaping () -> Void) -> DispatchWorkItem {
		let workItem = DispatchWorkItem(block: closure)
		schedule(after: delay, execute: workItem)
		return workItem
	}

	@discardableResult
	func schedule(at date: Date, execute closure: @escaping () -> Void) -> DispatchWorkItem {
		let workItem = DispatchWorkItem(block: closure)
		schedule(at: date, execute: workItem)
		return workItem
	}
}
#endif
