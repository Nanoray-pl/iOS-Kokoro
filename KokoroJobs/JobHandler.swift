//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import Combine
import Foundation

public typealias JobHandlerIdentifier = String

public protocol JobHandler: class {
	associatedtype JobType: Job
	associatedtype Parameters: Encodable & Decodable

	var identifier: JobHandlerIdentifier { get }

	func createJob(for parameters: Parameters, identifier: JobIdentifier) -> JobType

	func didSchedule(_ job: JobType)
	func didSucceed(_ job: JobType, result: JobType.Output)
	func canRetryAfterError(_ error: JobType.Failure, for job: JobType) -> Bool
	func didFail(_ job: JobType, error: JobType.Failure)
}

public extension JobHandler {
	func didSchedule(_ job: JobType) {}

	func canRetryAfterError(_ error: JobType.Failure, for job: JobType) -> Bool {
		return true
	}

	func eraseToAnyJobHandler() -> AnyJobHandler<JobType, Parameters> {
		return (self as? AnyJobHandler<JobType, Parameters>) ?? .init(wrapping: self)
	}
}

public extension JobHandler where JobType.Failure == Never {
	func didFail(_ job: JobType, error: Never) {}
}

public final class AnyJobHandler<JobType: Job, Parameters: Encodable & Decodable>: JobHandler {
	private let identifierClosure: () -> JobHandlerIdentifier
	private let createJobClosure: (Parameters, JobIdentifier) -> JobType
	private let didScheduleClosure: (JobType) -> Void
	private let didSucceedClosure: (JobType, JobType.Output) -> Void
	private let canRetryAfterErrorClosure: (JobType.Failure, JobType) -> Bool
	private let didFailClosure: (JobType, JobType.Failure) -> Void

	public var identifier: JobHandlerIdentifier {
		return identifierClosure()
	}

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: JobHandler, Wrapped.JobType == JobType, Wrapped.Parameters == Parameters {
		identifierClosure = { wrapped.identifier }
		createJobClosure = { wrapped.createJob(for: $0, identifier: $1) }
		didScheduleClosure = { wrapped.didSchedule($0) }
		didSucceedClosure = { wrapped.didSucceed($0, result: $1) }
		canRetryAfterErrorClosure = { wrapped.canRetryAfterError($0, for: $1) }
		didFailClosure = { wrapped.didFail($0, error: $1) }
	}

	public func createJob(for parameters: Parameters, identifier: JobIdentifier) -> JobType {
		return createJobClosure(parameters, identifier)
	}

	public func didSchedule(_ job: JobType) {
		didScheduleClosure(job)
	}

	public func didSucceed(_ job: JobType, result: JobType.Output) {
		didSucceedClosure(job, result)
	}

	public func canRetryAfterError(_ error: JobType.Failure, for job: JobType) -> Bool {
		return canRetryAfterErrorClosure(error, job)
	}

	public func didFail(_ job: JobType, error: JobType.Failure) {
		didFailClosure(job, error)
	}
}

public typealias JobIdentifier = UUID

public protocol Job: class {
	associatedtype Output
	associatedtype Failure: Error

	var identifier: JobIdentifier { get }

	func execute() -> AnyPublisher<Output, Failure>
}
