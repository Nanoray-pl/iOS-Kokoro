//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Foundation
import KokoroUtils

public class UserDefaultsJobEntryStorage: JobEntryStorage {
	private struct ComplexJobInfo: Codable {
		let jobIdentifier: JobIdentifier
		let handlerIdentifier: JobHandlerIdentifier
		let parametersData: Data
		var persistedScheduleParametersData: Data
	}

	public var jobInfos: [JobInfo] {
		return complexJobInfos.map { .init(jobIdentifier: $0.jobIdentifier, handlerIdentifier: $0.handlerIdentifier) }
	}

	private let logger: Logger

	private let userDefaults: UserDefaults
	private let userDefaultsKey: String
	private let decoder: AnyTopLevelDecoder<Data>
	private let encoder: AnyTopLevelEncoder<Data>
	private var complexJobInfos: [ComplexJobInfo]

	public convenience init(logger: Logger, userDefaults: UserDefaults = .standard, key userDefaultsKey: String) {
		self.init(logger: logger, userDefaults: userDefaults, key: userDefaultsKey, decoder: JSONDecoder(), encoder: JSONEncoder())
	}

	public init<Decoder, Encoder>(logger: Logger, userDefaults: UserDefaults = .standard, key userDefaultsKey: String, decoder: Decoder, encoder: Encoder) where Decoder: TopLevelDecoder, Decoder.Input == Data, Encoder: TopLevelEncoder, Encoder.Output == Data {
		self.logger = logger
		self.userDefaults = userDefaults
		self.userDefaultsKey = userDefaultsKey
		self.encoder = encoder.eraseToAnyTopLevelEncoder()
		self.decoder = decoder.eraseToAnyTopLevelDecoder()

		complexJobInfos = []
		if let data = userDefaults.data(forKey: userDefaultsKey) {
			do {
				complexJobInfos = try decoder.decode([ComplexJobInfo].self, from: data)
				logger.info("Loaded persisted job data: \(complexJobInfos.count) job(s)")
			} catch {
				logger.error("Cannot decode persisted jobs; ignoring existing structure: \(error)")
			}
		} else {
			logger.info("No persisted job data found")
		}
	}

	public func jobs<Handler: JobHandler>(for handler: Handler) -> [(job: Handler.JobType, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters)] {
		return complexJobInfos
			.filter { $0.handlerIdentifier == handler.identifier }
			.compactMap {
				do {
					let parameters = try decoder.decode(Handler.Parameters.self, from: $0.parametersData)
					let persistedScheduleParameters = try decoder.decode(JobManagerPersistedScheduleParameters.self, from: $0.persistedScheduleParametersData)
					let job = handler.createJob(for: parameters, identifier: $0.jobIdentifier)
					return (job: job, parameters: parameters, persistedScheduleParameters: persistedScheduleParameters)
				} catch {
					logger.error("Cannot decode job parameters or persisted schedule parameters: \(error)")
					return nil
				}
			}
	}

	public func storeJobEntry<Handler: JobHandler>(for job: Handler.JobType, via handler: Handler, parameters: Handler.Parameters, persistedScheduleParameters: JobManagerPersistedScheduleParameters) {
		do {
			let parametersData = try encoder.encode(parameters)
			let persistedScheduleParametersData = try encoder.encode(persistedScheduleParameters)

			privateRemoveJobEntry(with: job.identifier)
			complexJobInfos.append(
				.init(
					jobIdentifier: job.identifier,
					handlerIdentifier: handler.identifier,
					parametersData: parametersData,
					persistedScheduleParametersData: persistedScheduleParametersData
				)
			)
			persist()
		} catch {
			logger.error("Cannot encode job parameters or persisted schedule parameters: \(error)")
		}
	}

	public func updatePersistedScheduleParameters(jobIdentifier: JobIdentifier, persistedScheduleParameters: JobManagerPersistedScheduleParameters) {
		do {
			guard let index = complexJobInfos.firstIndex(where: { $0.jobIdentifier == jobIdentifier }) else { return }
			let persistedScheduleParametersData = try encoder.encode(persistedScheduleParameters)
			complexJobInfos[index].persistedScheduleParametersData = persistedScheduleParametersData
			persist()
		} catch {
			logger.error("Cannot encode persisted schedule parameters: \(error)")
		}
	}

	public func removeJobEntry(with identifier: JobIdentifier) {
		privateRemoveJobEntry(with: identifier)
		persist()
	}

	private func privateRemoveJobEntry(with identifier: JobIdentifier) {
		complexJobInfos.removeFirst(where: { $0.jobIdentifier == identifier })
	}

	private func persist() {
		do {
			let data = try encoder.encode(complexJobInfos)
			userDefaults.set(data, forKey: userDefaultsKey)
		} catch {
			logger.error("Cannot encode persisted jobs: \(error)")
		}
	}
}
#endif
