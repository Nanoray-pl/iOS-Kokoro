//
//  Created on 26/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

extension RunLoop: Scheduler {
	public var currentDate: Date {
		return Date()
	}

	public func schedule(at date: Date, execute workItem: DispatchWorkItem) {
		schedule(after: .init(date)) {
			if !workItem.isCancelled {
				workItem.perform()
			}
		}
	}

	public func schedule(after delay: TimeInterval, execute workItem: DispatchWorkItem) {
		schedule(at: Date().addingTimeInterval(delay), execute: workItem)
	}
}
#endif
