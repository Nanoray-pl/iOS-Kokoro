//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class SchedulingHttpClient<Scheduler: Combine.Scheduler>: HttpClient {
	private let wrapped: HttpClient
	fileprivate let scheduler: Scheduler
	public var delay: Scheduler.SchedulerTimeType.Stride?

	public init(wrapping wrapped: HttpClient, scheduler: Scheduler, delay: Scheduler.SchedulerTimeType.Stride? = nil) {
		self.wrapped = wrapped
		self.scheduler = scheduler
		self.delay = delay
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		if let delay = delay {
			return wrapped.request(request)
				.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
				.delay(for: delay, scheduler: scheduler)
				.eraseToAnyPublisher()
		} else {
			return wrapped.request(request)
				.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
				.receive(on: scheduler)
				.eraseToAnyPublisher()
		}
	}
}

public extension HttpClient {
	func scheduling<Scheduler: Combine.Scheduler>(on scheduler: Scheduler, delay: Scheduler.SchedulerTimeType.Stride? = nil) -> HttpClient {
		return SchedulingHttpClient(wrapping: self, scheduler: scheduler, delay: delay)
	}
}
#endif
