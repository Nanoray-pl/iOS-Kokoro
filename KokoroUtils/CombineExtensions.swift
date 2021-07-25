//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public class CancelBag {
	fileprivate var cancellableSet = Set<AnyCancellable>()

	public init() {}
}

public extension Future {
	// used to workaround an Xcode bug crashing SourceKit when wrapping Future with Deferred (too many wrapped closures, Xcode goes dumb)
	static func deferred(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) -> Deferred<Future<Output, Failure>> {
		return Deferred { Future(attemptToFulfill) }
	}
}

public extension Publisher {
	@discardableResult
	func sinkResult(storingIn bag: CancelBag, _ closure: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
		var capturedCancellable: AnyCancellable?
		let cancellable = onCancel {
			if let cancellable = capturedCancellable {
				bag.cancellableSet.remove(cancellable)
				capturedCancellable = nil
			}
		}
		.sinkResult {
			if let cancellable = capturedCancellable {
				bag.cancellableSet.remove(cancellable)
				capturedCancellable = nil
			}
			closure($0)
		}
		capturedCancellable = cancellable

		bag.cancellableSet.insert(cancellable)
		return cancellable
	}

	func sinkResult(_ closure: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
		return sink(receiveCompletion: {
			switch $0 {
			case .finished:
				break
			case let .failure(error):
				closure(.failure(error))
			}
		}, receiveValue: {
			closure(.success($0))
		})
	}

	func sinkResult<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, _ closure: @escaping (Result<Output, Failure>) -> Void) {
		return sink(storingIn: keyPath, onWeak: object, receiveCompletion: {
			switch $0 {
			case .finished:
				break
			case let .failure(error):
				closure(.failure(error))
			}
		}, receiveValue: {
			closure(.success($0))
		})
	}

	func sink<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void), receiveValue: @escaping ((Self.Output) -> Void)) {
		let cancellable = sink(receiveCompletion: { [weak object] in
			receiveCompletion($0)
			object?[keyPath: keyPath] = nil
		}, receiveValue: receiveValue)
		object[keyPath: keyPath] = cancellable
	}

	@discardableResult
	func sink(storingIn bag: CancelBag, receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void, receiveValue: @escaping (Self.Output) -> Void) -> AnyCancellable {
		var capturedCancellable: AnyCancellable?
		let cancellable = onCancel {
			if let cancellable = capturedCancellable {
				bag.cancellableSet.remove(cancellable)
				capturedCancellable = nil
			}
		}
		.sink(receiveCompletion: {
			if let cancellable = capturedCancellable {
				bag.cancellableSet.remove(cancellable)
				capturedCancellable = nil
			}
			receiveCompletion($0)
		}, receiveValue: receiveValue)
		capturedCancellable = cancellable

		bag.cancellableSet.insert(cancellable)
		return cancellable
	}

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

	func onError(_ closure: @escaping (Failure) -> Void) -> Publishers.MapError<Self, Failure> {
		return mapError {
			closure($0)
			return $0
		}
	}

	func onCancel(_ closure: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		return handleEvents(receiveCancel: closure)
	}

	func onStart(_ closure: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		let lock = FoundationLock()
		var didCallClosure = false
		return handleEvents(receiveSubscription: { _ in
			lock.acquireAndRun {
				if !didCallClosure {
					didCallClosure = true
					closure()
				}
			}
		})
	}

	func onOutput(_ closure: @escaping (Self.Output) -> Void) -> Publishers.Map<Self, Self.Output> {
		return map {
			closure($0)
			return $0
		}
	}

	func tryOnOutput(_ closure: @escaping (Self.Output) throws -> Void) -> Publishers.TryMap<Self, Self.Output> {
		return tryMap {
			try closure($0)
			return $0
		}
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

public extension Publisher where Failure == Never {
	@discardableResult
	func sink(storingIn bag: CancelBag, receiveValue: @escaping (Self.Output) -> Void) -> AnyCancellable {
		return sink(storingIn: bag, receiveCompletion: { _ in }, receiveValue: receiveValue)
	}

	func sink<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, receiveValue: @escaping (Self.Output) -> Void) {
		let cancellable = sink { [weak object] in
			receiveValue($0)
			object?[keyPath: keyPath] = nil
		}
		object[keyPath: keyPath] = cancellable
	}

	@discardableResult
	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) {
			object[keyPath: keyPath] = $0
		}
	}

	@discardableResult
	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, on object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) {
			object[keyPath: keyPath] = $0
		}
	}

	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, on object: Root) -> AnyCancellable {
		return sink {
			object[keyPath: keyPath] = $0
		}
	}

	@discardableResult
	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root) -> AnyCancellable {
		return sink { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	@discardableResult
	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root) -> AnyCancellable {
		return sink { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root, storingIn cancellableKeyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>) {
		let cancellable = sink { [weak object] in
			object?[keyPath: keyPath] = $0
			object?[keyPath: cancellableKeyPath] = nil
		}
		object[keyPath: cancellableKeyPath] = cancellable
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root, storingIn cancellableKeyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>) {
		let cancellable = sink { [weak object] in
			object?[keyPath: keyPath] = $0
			object?[keyPath: cancellableKeyPath] = nil
		}
		object[keyPath: cancellableKeyPath] = cancellable
	}

	func assign<Root: AnyObject, CancellableRoot: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root, storingIn cancellableKeyPath: ReferenceWritableKeyPath<CancellableRoot, Combine.AnyCancellable?>, onWeak cancellableRoot: CancellableRoot) {
		let cancellable = sink { [weak object, weak cancellableRoot] in
			object?[keyPath: keyPath] = $0
			cancellableRoot?[keyPath: cancellableKeyPath] = nil
		}
		cancellableRoot[keyPath: cancellableKeyPath] = cancellable
	}

	func assign<Root: AnyObject, CancellableRoot: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root, storingIn cancellableKeyPath: ReferenceWritableKeyPath<CancellableRoot, Combine.AnyCancellable?>, onWeak cancellableRoot: CancellableRoot) {
		let cancellable = sink { [weak object, weak cancellableRoot] in
			object?[keyPath: keyPath] = $0
			cancellableRoot?[keyPath: cancellableKeyPath] = nil
		}
		cancellableRoot[keyPath: cancellableKeyPath] = cancellable
	}
}
#endif
