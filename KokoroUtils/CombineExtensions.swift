//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public class CancelBag {
	fileprivate var cancellableSet = Set<AnyCancellable>()
}

public extension Publisher {
	func sinkResult(storingIn bag: CancelBag, _ closure: @escaping (Result<Output, Failure>) -> Void) {
		var cancellable: AnyCancellable!
		cancellable = sinkResult {
			bag.cancellableSet.remove(cancellable)
			closure($0)
		}
		bag.cancellableSet.insert(cancellable)
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

	func sink<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void), receiveValue: @escaping ((Self.Output) -> Void)) {
		let cancellable = sink(receiveCompletion: { [weak object] in
			receiveCompletion($0)
			object?[keyPath: keyPath] = nil
		}, receiveValue: receiveValue)
		object[keyPath: keyPath] = cancellable
	}

	func sink(storingIn bag: CancelBag, receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void, receiveValue: @escaping (Self.Output) -> Void) {
		// optional, because publishers like Just or Never return a nil cancellable
		var cancellable: AnyCancellable?
		cancellable = sink(receiveCompletion: {
			if let cancellable = cancellable {
				bag.cancellableSet.remove(cancellable)
			}
			receiveCompletion($0)
		}, receiveValue: receiveValue)
		if let cancellable = cancellable {
			bag.cancellableSet.insert(cancellable)
		}
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

extension Publisher where Failure == Never {
	func sink(storingIn bag: CancelBag, receiveValue: @escaping (Self.Output) -> Void) {
		return sink(storingIn: bag, receiveCompletion: { _ in }, receiveValue: receiveValue)
	}

	func sink<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, receiveValue: @escaping (Self.Output) -> Void) {
		let cancellable = sink { [weak object] in
			receiveValue($0)
			object?[keyPath: keyPath] = nil
		}
		object[keyPath: keyPath] = cancellable
	}

	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root, storingIn bag: CancelBag) {
		return sink(storingIn: bag) {
			object[keyPath: keyPath] = $0
		}
	}

	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, on object: Root, storingIn bag: CancelBag) {
		return sink(storingIn: bag) {
			object[keyPath: keyPath] = $0
		}
	}

	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, on object: Root) -> AnyCancellable {
		return sink {
			object[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root, storingIn bag: CancelBag) {
		return sink(storingIn: bag) { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root) -> AnyCancellable {
		return sink { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root, storingIn bag: CancelBag) {
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
