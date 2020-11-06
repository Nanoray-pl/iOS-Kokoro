//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

fileprivate extension Publisher {
	func scheduling<Scheduler: Combine.Scheduler>(via client: SchedulingHttpClient<Scheduler>) -> AnyPublisher<Output, Failure> {
		if let delay = client.delay {
			return buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
				.delay(for: delay, scheduler: client.scheduler)
				.eraseToAnyPublisher()
		} else {
			return buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
				.receive(on: client.scheduler)
				.eraseToAnyPublisher()
		}
	}
}

public class SchedulingHttpClient<Scheduler: Combine.Scheduler>: HttpClient {
	private let wrapped: HttpClient
	fileprivate let scheduler: Scheduler
	public var delay: Scheduler.SchedulerTimeType.Stride?

	public init(wrapping wrapped: HttpClient, scheduler: Scheduler, delay: Scheduler.SchedulerTimeType.Stride? = nil) {
		self.wrapped = wrapped
		self.scheduler = scheduler
		self.delay = delay
	}

	public func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error> {
		return wrapped.requestOptional(request).scheduling(via: self)
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		return wrapped.request(request).scheduling(via: self)
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return wrapped.request(request).scheduling(via: self)
	}
}

public extension HttpClient {
	func scheduling<Scheduler: Combine.Scheduler>(on scheduler: Scheduler, delay: Scheduler.SchedulerTimeType.Stride? = nil) -> HttpClient {
		return SchedulingHttpClient(wrapping: self, scheduler: scheduler, delay: delay)
	}
}
#endif
