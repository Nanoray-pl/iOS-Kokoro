//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public extension URLSession {
	func dataTaskProgressPublisher(for request: URLRequest) -> UrlSessionDataTaskProgressPublisher {
		return UrlSessionDataTaskProgressPublisher(session: self, request: request)
	}
}

public class UrlSessionDataTaskProgressPublisher: Publisher {
	public enum Output {
		case progress(_ progress: Progress)
		case output(data: Data, response: URLResponse)

		public enum Progress {
			case indeterminate
			case determinate(processedByteCount: Int, expectedByteCount: Int)
		}
	}

	public typealias Failure = URLError

	private let session: URLSession
	private let request: URLRequest
	private let subject = PassthroughSubject<Output, Failure>()
	private let lock = NSObject()
	private var subscriptionCount = 0
	private var dataTask: URLSessionDataTask?
	private var fractionObservation: NSKeyValueObservation?
	private var indeterminateObservation: NSKeyValueObservation?

	public init(session: URLSession, request: URLRequest) {
		self.session = session
		self.request = request
	}

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		objc_sync_enter(lock)
		defer { objc_sync_exit(lock) }

		subscriptionCount += 1
		if subscriptionCount == 1 {
			let dataTask = session.dataTask(with: request) { data, response, error in
				if let error = error {
					self.subject.send(completion: .failure(error as? URLError ?? .init(.unknown)))
					return
				}

				guard let data = data, let response = response else {
					self.subject.send(completion: .failure(.init(.unknown)))
					return
				}

				self.subject.send(.output(data: data, response: response))
				self.subject.send(completion: .finished)
			}
			fractionObservation = dataTask.progress.observe(\.fractionCompleted, changeHandler: { progress, _ in self.updateProgress(progress) })
			indeterminateObservation = dataTask.progress.observe(\.isIndeterminate, changeHandler: { progress, _ in self.updateProgress(progress) })
			self.dataTask = dataTask
			dataTask.resume()
		}

		let subscription = Subscription(publisher: self, subscriber: subscriber)
		subscriber.receive(subscription: subscription)
	}

	private func updateProgress(_ progress: Progress) {
		guard let dataTask = dataTask else { return }

		if progress.isIndeterminate {
			subject.send(.progress(.indeterminate))
		} else {
			subject.send(.progress(.determinate(processedByteCount: Int(dataTask.countOfBytesReceived), expectedByteCount: Int(dataTask.countOfBytesExpectedToReceive))))
		}
	}

	private func dropSubscription() {
		objc_sync_enter(self)
		defer { objc_sync_exit(lock) }

		subscriptionCount -= 1
		if subscriptionCount == 0 {
			fractionObservation = nil
			indeterminateObservation = nil
			dataTask?.cancel()
			dataTask = nil
		}
	}

	private class Subscription: Combine.Subscription {
		private var publisher: UrlSessionDataTaskProgressPublisher?
		private var cancellable: AnyCancellable?

		init<S>(publisher: UrlSessionDataTaskProgressPublisher, subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
			self.publisher = publisher

			cancellable = publisher.subject.sink(receiveCompletion: { completion in
				subscriber.receive(completion: completion)
			}, receiveValue: { value in
				_ = subscriber.receive(value)
			})
		}

		func request(_ demand: Subscribers.Demand) {}

		func cancel() {
			cancellable?.cancel()
			cancellable = nil
			publisher?.dropSubscription()
			publisher = nil
		}
	}
}
#endif
