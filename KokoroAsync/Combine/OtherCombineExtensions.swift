//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public extension Future {
	// used to workaround an Xcode bug crashing SourceKit when wrapping Future with Deferred (too many wrapped closures, Xcode goes dumb)
	static func deferred(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) -> Deferred<Future<Output, Failure>> {
		return Deferred { Future(attemptToFulfill) }
	}
}

public extension Future where Failure == Error {
	static func `try`(_ attemptToFulfill: @escaping () throws -> Output) -> Deferred<Future<Output, Error>> {
		return Deferred {
			Future {
				do {
					$0(.success(try attemptToFulfill()))
				} catch {
					$0(.failure(error))
				}
			}
		}
	}
}

public extension Publisher {
	func delayStart<S: Combine.Scheduler>(for interval: S.SchedulerTimeType.Stride, tolerance: S.SchedulerTimeType.Stride? = nil, scheduler: S, options: S.SchedulerOptions? = nil) -> AnyPublisher<Output, Failure> {
		var instance: Self! = self
		return Deferred { Just(()) }
			.setFailureType(to: Failure.self)
			.delay(for: interval, tolerance: tolerance, scheduler: scheduler, options: options)
			.flatMap { _ -> Self in
				let result = instance!
				instance = nil
				return result
			}
			.eraseToAnyPublisher()
	}

	func handleError(_ handler: @escaping (Self.Failure) -> Void) -> Publishers.Catch<Self, Empty<Output, Never>> {
		return `catch` { error -> Empty<Output, Never> in
			handler(error)
			return Empty()
		}
	}

	func tryFlatMap<P>(maxPublishers: Subscribers.Demand = .unlimited, _ transform: @escaping (Self.Output) throws -> P) -> Publishers.FlatMap<AnyPublisher<Self.Output, Error>, Publishers.MapError<Self, Error>> where P: Publisher, P.Output == Self.Output {
		return mapError { $0 as Error }
			.flatMap(maxPublishers: maxPublishers) { value -> AnyPublisher<Self.Output, Error> in
				do {
					return try transform(value)
						.mapError { $0 as Error }
						.eraseToAnyPublisher()
				} catch {
					return Fail(outputType: Self.Output.self, failure: error)
						.eraseToAnyPublisher()
				}
			}
	}

	func replaceNilWithError<T>(_ error: Failure) -> AnyPublisher<T, Failure> where Self.Output == T? {
		return flatMap { output -> AnyPublisher<T, Failure> in
			if let output = output {
				return Just(output)
					.setFailureType(to: Failure.self)
					.eraseToAnyPublisher()
			} else {
				return Fail(error: error)
					.eraseToAnyPublisher()
			}
		}
		.eraseToAnyPublisher()
	}
}
#endif
