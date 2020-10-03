//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

fileprivate extension Publisher {
	func delay<Scheduler: Combine.Scheduler>(via client: SchedulingHttpClient<Scheduler>) -> AnyPublisher<Output, Failure> {
		var publisher = self
			.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
			.eraseToAnyPublisher()

		if let delay = client.delay {
			publisher = publisher
				.delay(for: delay, scheduler: client.scheduler)
				.eraseToAnyPublisher()
		} else {
			publisher = publisher
				.receive(on: client.scheduler)
				.eraseToAnyPublisher()
		}

		return publisher
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
		return wrapped.requestOptional(request).delay(via: self)
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		return wrapped.request(request).delay(via: self)
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return wrapped.request(request).delay(via: self)
	}
}

public extension HttpClient {
	func scheduling<Scheduler: Combine.Scheduler>(on scheduler: Scheduler, delay: Scheduler.SchedulerTimeType.Stride? = nil) -> HttpClient {
		return SchedulingHttpClient(wrapping: self, scheduler: scheduler, delay: delay)
	}
}
#endif
