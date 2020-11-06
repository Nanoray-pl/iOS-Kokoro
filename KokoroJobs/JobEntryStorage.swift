//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Foundation

public struct JobInfo {
	public let jobIdentifier: JobIdentifier
	public let handlerIdentifier: JobHandlerIdentifier

	public init(jobIdentifier: JobIdentifier, handlerIdentifier: JobHandlerIdentifier) {
		self.jobIdentifier = jobIdentifier
		self.handlerIdentifier = handlerIdentifier
	}
}

public protocol JobEntryStorage: class {
	var jobInfos: [JobInfo] { get }

	func jobs<Handler: JobHandler>(for handler: Handler) -> [(job: Handler.JobType, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters)]
	func storeJobEntry<Handler: JobHandler>(for job: Handler.JobType, via handler: Handler, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters)
	func updatePersistedScheduleParameters(jobIdentifier: JobIdentifier, persistedScheduleParameters: JobManagerPersistedScheduleParameters)
	func removeJobEntry(with identifier: JobIdentifier)
}
#endif
