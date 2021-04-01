//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public class MockScheduler: Scheduler {
	private struct Entry {
		let date: Date
		let workItem: DispatchWorkItem
	}

	public private(set) var currentDate: Date
	private var workItemsToExecute = [DispatchWorkItem]()
	private var entries = SortedArray<Entry>(by: \.date)

	public init(startingDate: Date = Date()) {
		currentDate = startingDate
	}

	public func execute(_ workItem: DispatchWorkItem) {
		workItemsToExecute.append(workItem)
	}

	public func schedule(at date: Date, execute workItem: DispatchWorkItem) {
		entries.removeFirst { $0.workItem === workItem }
		if date < currentDate && !workItem.isCancelled {
			workItem.perform()
			return
		}

		entries.insert(.init(date: date, workItem: workItem))
	}

	public func schedule(after delay: TimeInterval, execute workItem: DispatchWorkItem) {
		entries.removeFirst { $0.workItem === workItem }
		if delay <= 0 && !workItem.isCancelled {
			workItem.perform()
			return
		}

		let date = currentDate.addingTimeInterval(delay)
		entries.insert(.init(date: date, workItem: workItem))
	}

	public func advanceTime(to date: Date) {
		advanceTime(by: date.timeIntervalSince(currentDate))
	}

	public func advanceTime(by timeAdvancement: TimeInterval) {
		workItemsToExecute.forEach {
			if !$0.isCancelled {
				$0.perform()
			}
		}
		workItemsToExecute.removeAll()

		guard let entry = entries.first else {
			currentDate = currentDate.addingTimeInterval(timeAdvancement)
			return
		}

		let timeUntilFirstWorkItem = entry.date.timeIntervalSince(currentDate)
		if timeUntilFirstWorkItem < timeAdvancement {
			currentDate = currentDate.addingTimeInterval(timeUntilFirstWorkItem)
			if !entry.workItem.isCancelled {
				entry.workItem.perform()
			}
			entries.remove(at: 0)
			advanceTime(by: timeAdvancement - timeUntilFirstWorkItem)
		} else {
			currentDate = currentDate.addingTimeInterval(timeAdvancement)
		}
	}
}
#endif
