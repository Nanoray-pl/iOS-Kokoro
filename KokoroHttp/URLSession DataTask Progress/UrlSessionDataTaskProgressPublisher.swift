//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

public extension URLSession {
	func dataTaskProgressPublisher(for request: URLRequest) -> UrlSessionDataTaskProgressPublisher {
		return UrlSessionDataTaskProgressPublisher(session: self, request: request)
	}
}

public class UrlSessionDataTaskProgressPublisher: Publisher {
	public typealias Output = UrlSessionDataTaskProgress
	public typealias Failure = URLError

	private let session: URLSession
	private let request: URLRequest
	private let subject = CurrentValueSubject<Output, Failure>(.sendProgress(.indeterminate()))
	private let lock: Lock = DefaultLock()
	private var subscriptionCount = 0
	private var dataTask: URLSessionDataTask?
	private lazy var kvoObserver = KVOObserver { [weak self] in self?.updateProgress() }

	public init(session: URLSession, request: URLRequest) {
		self.session = session
		self.request = request
	}

	deinit {
		lock.acquireAndRun {
			kvoObserver.stopObservingAll()
		}
	}

	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		lock.acquireAndRun {
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

				kvoObserver.observe(\.isIndeterminate, of: dataTask.progress)
				kvoObserver.observe(\.countOfBytesSent, of: dataTask)
				kvoObserver.observe(\.countOfBytesExpectedToSend, of: dataTask)
				kvoObserver.observe(\.countOfBytesReceived, of: dataTask)
				kvoObserver.observe(\.countOfBytesExpectedToReceive, of: dataTask)
				self.dataTask = dataTask
				dataTask.resume()
			}

			let subscription = Subscription(publisher: self, subscriber: subscriber)
			subscriber.receive(subscription: subscription)
		}
	}

	private func updateProgress() {
		lock.acquireAndRun {
			guard let dataTask = dataTask else { return }

			if dataTask.countOfBytesExpectedToReceive > 0 {
				publishProgressValue(.receiveProgress(.determinate(
					processedByteCount: Swift.max(Int(dataTask.countOfBytesReceived), 0),
					expectedByteCount: Swift.max(Int(dataTask.countOfBytesExpectedToReceive), 0)
				)))
			} else if dataTask.countOfBytesReceived > 0 {
				publishProgressValue(.receiveProgress(.indeterminate(
					processedByteCount: Swift.max(Int(dataTask.countOfBytesReceived), 0)
				)))
			} else if dataTask.countOfBytesExpectedToSend > 0 {
				publishProgressValue(.sendProgress(.determinate(
					processedByteCount: Swift.max(Int(dataTask.countOfBytesSent), 0),
					expectedByteCount: Swift.max(Int(dataTask.countOfBytesExpectedToSend), 0)
				)))
			} else {
				publishProgressValue(.sendProgress(.indeterminate(
					processedByteCount: Swift.max(Int(dataTask.countOfBytesSent), 0)
				)))
			}
		}
	}

	private func publishProgressValue(_ value: Output) {
		lock.acquireAndRun {
			if subject.value != value {
				subject.send(value)
			}
		}
	}

	private func dropSubscription() {
		lock.acquireAndRun {
			subscriptionCount -= 1
			if subscriptionCount == 0 {
				kvoObserver.stopObservingAll()
				dataTask?.cancel()
				dataTask = nil
			}
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
