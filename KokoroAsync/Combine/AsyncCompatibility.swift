//
//  Created on 28/01/2022.
//  Copyright © 2022 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine
import KokoroUtils

// original source: https://github.com/zwaldowski/ConcurrencyCompatibility/blob/main/Sources/ConcurrencyCompatibility/Publisher.swift
@available(macOS, deprecated: 12, renamed: "Combine.AsyncThrowingPublisher")
@available(iOS, deprecated: 15, renamed: "Combine.AsyncThrowingPublisher")
@available(watchOS, deprecated: 8, renamed: "Combine.AsyncThrowingPublisher")
@available(tvOS, deprecated: 15, renamed: "Combine.AsyncThrowingPublisher")
public struct AsyncThrowingPublisher<P>: AsyncSequence where P: Publisher {
	public typealias Element = P.Output
	
	public struct Iterator: AsyncIteratorProtocol {
		class Base: AsyncIteratorProtocol {
			func next() async throws -> Element? {
				fatalError("Not overriden abstract member")
			}
		}
		
		@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
		class Native: Base {
			private var iterator: Combine.AsyncThrowingPublisher<P>.Iterator
			
			fileprivate init(_ publisher: P) {
				self.iterator = publisher.values.makeAsyncIterator()
			}
			
			override func next() async throws -> Element? {
				try await iterator.next()
			}
		}
		
		class Inner: Base, Subscriber, Combine.Cancellable {
			enum State {
				case awaitingSubscription(demand: Subscribers.Demand)
				case subscribed(Subscription)
				case terminal
			}
			
			private let lock: Lock = DefaultLock()
			private var state = State.awaitingSubscription(demand: .none)
			private var pendingContinuations = [UnsafeContinuation<P.Output?, Error>]()
			
			fileprivate init(_ publisher: P) {
				super.init()
				publisher.subscribe(self)
			}
			
			func receive(subscription: Subscription) {
				lock.acquireAndRun {
					switch state {
					case let .awaitingSubscription(demand):
						state = .subscribed(subscription)
						if demand > .none {
							subscription.request(demand)
						}
					case .subscribed, .terminal:
						subscription.cancel()
					}
				}
			}
			
			func receive(_ input: Element) -> Subscribers.Demand {
				return lock.acquireAndRun {
					switch state {
					case .subscribed:
						let continuation = pendingContinuations.isEmpty ? nil : pendingContinuations.removeFirst()
						continuation?.resume(returning: input)
					case .awaitingSubscription, .terminal:
						let continuationsToProcess = pendingContinuations
						pendingContinuations.removeAll()
						continuationsToProcess.forEach { $0.resume(returning: nil) }
					}
					return .none
				}
			}
			
			func receive(completion: Subscribers.Completion<P.Failure>) {
				lock.acquireAndRun {
					state = .terminal
					let continuationsToProcess = pendingContinuations
					pendingContinuations.removeAll()
					
					if let continuation = continuationsToProcess.first {
						switch completion {
						case .finished:
							continuation.resume(returning: nil)
						case let .failure(error):
							continuation.resume(throwing: error)
						}
					}
					
					continuationsToProcess.dropFirst().forEach { $0.resume(returning: nil) }
				}
			}
			
			func cancel() {
				lock.acquireAndRun {
					let continuationsToProcess = pendingContinuations
					pendingContinuations.removeAll()
					
					switch state {
					case let .subscribed(upstream):
						state = .terminal
						upstream.cancel()
					case .awaitingSubscription:
						state = .terminal
					case .terminal:
						break
					}
					
					continuationsToProcess.forEach { $0.resume(returning: nil) }
				}
			}
			
			override func next() async throws -> Element? {
				return try await withTaskCancellationHandler {
					try await withUnsafeThrowingContinuation { continuation in
						lock.acquireAndRun {
							switch state {
							case .terminal:
								continuation.resume(returning: nil)
							case let .subscribed(upstream):
								pendingContinuations.append(continuation)
								upstream.request(.max(1))
							case let .awaitingSubscription(demand):
								pendingContinuations.append(continuation)
								state = .awaitingSubscription(demand: demand + 1)
							}
						}
					}
				} onCancel: {
					cancel()
				}
			}
		}
		
		private let base: Base
		
		fileprivate init(_ publisher: P) {
			if #available(macOS 12, iOS 15, watchOS 8, tvOS 15, *) {
				base = Native(publisher)
			} else {
				base = Inner(publisher)
			}
		}
		
		public mutating func next() async throws -> P.Output? {
			return try await base.next()
		}
	}
	
	private let publisher: P
	
	public init(_ publisher: P) {
		self.publisher = publisher
	}
	
	public func makeAsyncIterator() -> Iterator {
		return Iterator(publisher)
	}
}
#endif
