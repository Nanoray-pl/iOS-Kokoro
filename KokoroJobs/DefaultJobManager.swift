//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

private struct FakeCodableWrapper: Codable {
	let value: Any

	init(_ value: Any) {
		self.value = value
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		throw DecodingError.dataCorruptedError(in: container, debugDescription: "FakeCodableWrapper cannot actually be decoded")
	}

	func encode(to encoder: Encoder) throws {
		let container = encoder.singleValueContainer()
		throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "FakeCodableWrapper cannot actually be encoded"))
	}
}

private class UntypedJobHandler: JobHandler {
	typealias JobType = UntypedJob
	typealias Parameters = FakeCodableWrapper

	private let identifierClosure: () -> JobHandlerIdentifier
	private let createJobClosure: (Parameters, JobIdentifier) -> JobType
	private let didScheduleClosure: (JobType) -> Void
	private let didSucceedClosure: (JobType, JobType.Output) -> Void
	private let canRetryAfterErrorClosure: (JobType.Failure, JobType) -> Bool
	private let didFailClosure: (JobType, JobType.Failure) -> Void

	var identifier: JobHandlerIdentifier {
		return identifierClosure()
	}

	init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: JobHandler {
		identifierClosure = { wrapped.identifier }
		createJobClosure = { wrapped.createJob(for: $0 as! Wrapped.Parameters, identifier: $1) as! UntypedJob }
		didScheduleClosure = { wrapped.didSchedule($0.wrapped as! Wrapped.JobType) }
		didSucceedClosure = { wrapped.didSucceed($0.wrapped as! Wrapped.JobType, result: $1 as! Wrapped.JobType.Output) }
		canRetryAfterErrorClosure = { wrapped.canRetryAfterError($0 as! Wrapped.JobType.Failure, for: $1.wrapped as! Wrapped.JobType) }
		didFailClosure = { wrapped.didFail($0.wrapped as! Wrapped.JobType, error: $1 as! Wrapped.JobType.Failure) }
	}

	func createJob(for parameters: Parameters, identifier: JobIdentifier) -> JobType {
		return createJobClosure(parameters, identifier)
	}

	func didSchedule(_ job: JobType) {
		didScheduleClosure(job)
	}

	func didSucceed(_ job: JobType, result: JobType.Output) {
		didSucceedClosure(job, result)
	}

	func canRetryAfterError(_ error: Error, for job: UntypedJob) -> Bool {
		return canRetryAfterErrorClosure(error, job)
	}

	func didFail(_ job: JobType, error: JobType.Failure) {
		didFailClosure(job, error)
	}
}

private class UntypedJob: Job {
	let wrapped: Any
	private let identifierClosure: () -> JobIdentifier
	private let executeClosure: () -> AnyPublisher<Any, Error>

	var identifier: JobIdentifier {
		return identifierClosure()
	}

	init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: Job {
		self.wrapped = wrapped
		identifierClosure = { wrapped.identifier }
		executeClosure = { wrapped.execute().map { $0 as Any }.mapError { $0 as Error }.eraseToAnyPublisher() }
	}

	func execute() -> AnyPublisher<Any, Error> {
		return executeClosure()
	}
}

public class DefaultJobManager: JobManager, ObjectWith {
	private let entryStorage: JobEntryStorage
	private let scheduler: KokoroUtils.Scheduler
	private let logger: Logger

	private let lock = ObjcLock()
	private var handlers = [JobHandlerIdentifier: UntypedJobHandler]()
	private var jobs = [UntypedJob]()
	private var jobHandlers = [JobIdentifier: UntypedJobHandler]()
	private var runningJobs = [JobIdentifier: AnyCancellable]()
	private var persistedScheduleParameters = [JobIdentifier: JobManagerPersistedScheduleParameters]()
	private var workItem: DispatchWorkItem?

	public init(entryStorage: JobEntryStorage, scheduler: KokoroUtils.Scheduler = DispatchQueue.global(qos: .background), logger: Logger, dispatchQueue: DispatchQueue = .global(qos: .background)) {
		self.entryStorage = entryStorage
		self.logger = logger
		self.scheduler = scheduler
	}

	public func registerHandler<Handler: JobHandler>(_ handler: Handler) {
		lock.acquireAndRun {
			logger.debug("Registering handler: \(handler) (\(handler.identifier))")
			handlers[handler.identifier] = UntypedJobHandler(wrapping: handler)

			let existingJobs = entryStorage.jobs(for: handler)
			existingJobs.forEach {
				logger.info("Found persisted job \($0.job.identifier) for handler, rescheduling")
				let job = UntypedJob(wrapping: $0.job)
				jobs.append(job)
				jobHandlers[$0.job.identifier] = UntypedJobHandler(wrapping: handler)
				persistedScheduleParameters[$0.job.identifier] = $0.persistedScheduleParameters
			}
			rescheduleNextJob()
		}
	}

	public func unregisterHandler<Handler: JobHandler>(_ handler: Handler) {
		lock.acquireAndRun {
			logger.debug("Unregistering handler: \(handler) (\(handler.identifier))")

			let jobs = entryStorage.jobs(for: handler).map(\.job)
			jobs.forEach { cancelJob($0) }

			handlers[handler.identifier] = nil
			rescheduleNextJob()
		}
	}

	public func schedule<Handler: JobHandler>(via handler: Handler, parameters: Handler.Parameters, scheduleParameters: JobManagerScheduleParameters) -> Handler.JobType {
		return lock.acquireAndRun {
			let job = handler.createJob(for: parameters, identifier: .init())
			logger.info("Scheduling job \(job.identifier) for handler \(handler) (\(handler.identifier))")
			let persistedScheduleParameters = JobManagerPersistedScheduleParameters(backoff: scheduleParameters.backoff, lastDelay: nil, dispatchTime: Date().addingTimeInterval(scheduleParameters.initialDelay))
			jobs.append(UntypedJob(wrapping: job))
			jobHandlers[job.identifier] = UntypedJobHandler(wrapping: handler)
			self.persistedScheduleParameters[job.identifier] = persistedScheduleParameters
			entryStorage.storeJobEntry(for: job, via: handler, parameters: parameters, persistedScheduleParameters: persistedScheduleParameters)
			rescheduleNextJob()
			return job
		}
	}

	private func delayJob(_ job: UntypedJob) {
		lock.acquireAndRun {
			let persistedScheduleParameters = self.persistedScheduleParameters[job.identifier]!
			let delay: TimeInterval
			switch (lastDelay: persistedScheduleParameters.lastDelay, backoffPolicy: persistedScheduleParameters.backoff.policy) {
			case (.none, _):
				delay = persistedScheduleParameters.backoff.firstDelay
			case let (.some(lastDelay), .linear):
				delay = lastDelay + persistedScheduleParameters.backoff.firstDelay
			case let (.some(lastDelay), .exponential):
				delay = lastDelay * 2
			}
			self.persistedScheduleParameters[job.identifier] = .init(backoff: persistedScheduleParameters.backoff, lastDelay: delay, dispatchTime: Date().addingTimeInterval(delay))
			entryStorage.updatePersistedScheduleParameters(jobIdentifier: job.identifier, persistedScheduleParameters: persistedScheduleParameters)
			rescheduleNextJob()
		}
	}

	private func rescheduleNextJob() {
		lock.acquireAndRun {
			guard let firstJob = jobs.filter({ runningJobs[$0.identifier] == nil }).min(by: { persistedScheduleParameters[$0.identifier]!.dispatchTime }) else {
				logger.verbose("No jobs left to reschedule")
				return
			}

			workItem?.cancel()
			workItem = nil

			let workItem = DispatchWorkItem { [weak self] in
				self?.executeJob(firstJob)
			}
			self.workItem = workItem
			let delay = persistedScheduleParameters[firstJob.identifier]!.dispatchTime.timeIntervalSince(Date())
			logger.debug("Rescheduled job \(firstJob.identifier) - will run after \(delay)s")
			scheduler.schedule(after: delay, execute: workItem)
		}
	}

	private func executeJob(_ job: UntypedJob) {
		lock.acquireAndRun {
			guard let jobHandler = jobHandlers[job.identifier] else {
				logger.error("Tried to execute job \(job.identifier), but there is no handler registered for it")
				cancelJob(job)
				rescheduleNextJob()
				return
			}

			logger.info("Executing job \(job.identifier)")
			var manager: DefaultJobManager! = self
			runningJobs[job.identifier] = job.execute()
				.sink(
					receiveCompletion: { [logger] in
						manager.runningJobs[job.identifier] = nil
						switch $0 {
						case .finished:
							break
						case let .failure(error):
							logger.info("Job \(job.identifier) for handler \(jobHandler.identifier) failed")
							if jobHandler.canRetryAfterError(error, for: job) {
								logger.info("Error for job \(job.identifier) is non-fatal, delaying")
								manager.delayJob(job)
							} else {
								logger.warning("Error for job \(job.identifier) is fatal")
								jobHandler.didFail(job, error: error)
								manager.cancelJob(job)
							}
						}
						manager = nil
					}, receiveValue: { [logger] in
						logger.info("Job \(job.identifier) for handler \(jobHandler.identifier) succeeded")
						manager.cleanUpAfterJob(identifier: job.identifier)
						jobHandler.didSucceed(job, result: $0)
					}
				)
			jobHandler.didSchedule(job)
			rescheduleNextJob()
		}
	}

	public func cancelJob(with identifier: JobIdentifier) {
		lock.acquireAndRun {
			guard jobs.contains(where: { $0.identifier == identifier }) else { return }
			logger.info("Cancelling job \(identifier)")

			cleanUpAfterJob(identifier: identifier)
			rescheduleNextJob()
		}
	}

	private func cleanUpAfterJob(identifier: JobIdentifier) {
		lock.acquireAndRun {
			entryStorage.removeJobEntry(with: identifier)
			persistedScheduleParameters[identifier] = nil
			runningJobs[identifier] = nil
			jobHandlers[identifier] = nil
			jobs.removeFirst(where: { $0.identifier == identifier })
		}
	}
}
#endif
