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
	public enum Output: Hashable {
		case sendProgress(_ progress: Progress)
		case receiveProgress(_ progress: Progress)
		case output(data: Data, response: URLResponse)

		public enum Progress: Hashable {
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
	private var observations = [NSKeyValueObservation]()

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

			observations = [
				dataTask.progress.observe(\.isIndeterminate, changeHandler: { [weak self] _, _ in self?.updateProgress() }),
				dataTask.observe(\.countOfBytesSent, changeHandler: { [weak self] _, _ in self?.updateProgress() }),
				dataTask.observe(\.countOfBytesExpectedToSend, changeHandler: { [weak self] _, _ in self?.updateProgress() }),
				dataTask.observe(\.countOfBytesReceived, changeHandler: { [weak self] _, _ in self?.updateProgress() }),
				dataTask.observe(\.countOfBytesExpectedToReceive, changeHandler: { [weak self] _, _ in self?.updateProgress() }),
			]
			self.dataTask = dataTask
			dataTask.resume()
		}

		let subscription = Subscription(publisher: self, subscriber: subscriber)
		subscriber.receive(subscription: subscription)
	}

	private func updateProgress() {
		guard let dataTask = dataTask else { return }
		let progress = dataTask.progress

		if dataTask.countOfBytesExpectedToSend <= 0 {
			subject.send(.sendProgress(.indeterminate))
		} else if dataTask.countOfBytesSent < dataTask.countOfBytesExpectedToSend {
			subject.send(.sendProgress(.determinate(processedByteCount: Int(dataTask.countOfBytesSent), expectedByteCount: Int(dataTask.countOfBytesExpectedToSend))))
		} else if progress.isIndeterminate || dataTask.countOfBytesExpectedToReceive < 0 || (dataTask.countOfBytesExpectedToReceive == 0 && dataTask.countOfBytesReceived == 0) {
			subject.send(.receiveProgress(.indeterminate))
		} else {
			subject.send(.receiveProgress(.determinate(processedByteCount: Int(dataTask.countOfBytesReceived), expectedByteCount: Int(dataTask.countOfBytesExpectedToReceive))))
		}
	}

	private func dropSubscription() {
		objc_sync_enter(lock)
		defer { objc_sync_exit(lock) }

		subscriptionCount -= 1
		if subscriptionCount == 0 {
			observations = []
			dataTask?.cancel()
			dataTask = nil
		}
	}

	private class Subscription: Combine.Subscription {
		private var publisher: UrlSessionDataTaskProgressPublisher?
		private var cancellable: AnyCancellable?

		init<S>(publisher: UrlSessionDataTaskProgressPublisher, subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
			self.publisher = publisher

			cancellable = publisher.subject.removeDuplicates().sink(receiveCompletion: { completion in
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
