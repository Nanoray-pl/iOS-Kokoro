//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Foundation

public struct JobManagerBackoffCriteria: Codable {
	public enum Policy: String, Codable {
		case linear, exponential
	}

	public let firstDelay: TimeInterval
	public let policy: Policy

	public init(firstDelay: TimeInterval = 10, policy: Policy = .exponential) {
		self.firstDelay = firstDelay
		self.policy = policy
	}
}

public struct JobManagerScheduleParameters {
	public let backoff: JobManagerBackoffCriteria
	public let initialDelay: TimeInterval

	public init(backoff: JobManagerBackoffCriteria = .init(), initialDelay: TimeInterval = 0) {
		self.backoff = backoff
		self.initialDelay = initialDelay
	}
}

public struct JobManagerPersistedScheduleParameters: Codable {
	public let backoff: JobManagerBackoffCriteria
	public let lastDelay: TimeInterval?
	public let dispatchTime: Date

	public init(backoff: JobManagerBackoffCriteria, lastDelay: TimeInterval?, dispatchTime: Date) {
		self.backoff = backoff
		self.lastDelay = lastDelay
		self.dispatchTime = dispatchTime
	}
}

public protocol JobManager: AnyObject {
	func registerHandler<Handler: JobHandler>(_ handler: Handler)
	func unregisterHandler<Handler: JobHandler>(_ handler: Handler)

	@discardableResult
	func schedule<Handler: JobHandler>(via handler: Handler, parameters: Handler.Parameters, scheduleParameters: JobManagerScheduleParameters) -> Handler.JobType

	func cancelJob(with identifier: UUID)
}

public extension JobManager {
	@discardableResult
	func schedule<Handler: JobHandler>(via handler: Handler, parameters: Handler.Parameters) -> Handler.JobType {
		return schedule(via: handler, parameters: parameters, scheduleParameters: .init(backoff: .init(), initialDelay: 0))
	}

	func cancelJob<T>(_ job: T) where T: Job {
		cancelJob(with: job.identifier)
	}
}
#endif
