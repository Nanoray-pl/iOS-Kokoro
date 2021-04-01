//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

extension DispatchQueue: Scheduler {
	public var currentDate: Date {
		return Date()
	}

	public func execute(_ work: DispatchWorkItem) {
		async(execute: work)
	}

	public func schedule(at date: Date, execute workItem: DispatchWorkItem) {
		asyncAfter(deadline: .now() + date.timeIntervalSinceNow, execute: workItem)
	}

	public func schedule(after delay: TimeInterval, execute workItem: DispatchWorkItem) {
		asyncAfter(deadline: .now() + delay, execute: workItem)
	}
}
#endif
