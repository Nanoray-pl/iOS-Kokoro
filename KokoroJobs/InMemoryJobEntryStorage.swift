//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import Foundation

public class InMemoryJobEntryStorage: JobEntryStorage {
	private struct ComplexJobInfo {
		let jobIdentifier: JobIdentifier
		let handlerIdentifier: JobHandlerIdentifier
		let job: Any
		let parameters: Any
		var persistedScheduleParameters: JobManagerPersistedScheduleParameters
	}

	private var complexJobInfos = [ComplexJobInfo]()

	public var jobInfos: [JobInfo] {
		return complexJobInfos.map { .init(jobIdentifier: $0.jobIdentifier, handlerIdentifier: $0.handlerIdentifier) }
	}

	public init() {}

	public func jobs<Handler: JobHandler>(for handler: Handler) -> [(job: Handler.JobType, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters)] {
		return complexJobInfos
			.filter { $0.handlerIdentifier == handler.identifier && $0.job is Handler.JobType && $0.parameters is Handler.Parameters }
			.map { (job: $0.job as! Handler.JobType, parameters: $0.parameters as! Handler.Parameters, persistedScheduleParameters: $0.persistedScheduleParameters) }
	}

	public func storeJobEntry<Handler: JobHandler>(for job: Handler.JobType, via handler: Handler, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters) {
		removeJobEntry(with: job.identifier)

		complexJobInfos.append(.init(
			jobIdentifier: job.identifier,
			handlerIdentifier: handler.identifier,
			job: job,
			parameters: parameters,
			persistedScheduleParameters: persistedScheduleParameters
		))
	}

	public func updatePersistedScheduleParameters(jobIdentifier: JobIdentifier, persistedScheduleParameters: JobManagerPersistedScheduleParameters) {
		guard let index = complexJobInfos.firstIndex(where: { $0.jobIdentifier == jobIdentifier }) else { return }
		complexJobInfos[index].persistedScheduleParameters = persistedScheduleParameters
	}

	public func removeJobEntry(with identifier: JobIdentifier) {
		complexJobInfos.removeFirst(where: { $0.jobIdentifier == identifier })
	}
}
