//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine

public extension Publisher {
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
}

public extension Publisher where Failure == Never {
	func sink<Root: AnyObject>(storingIn keyPath: ReferenceWritableKeyPath<Root, Combine.AnyCancellable?>, onWeak object: Root, receiveValue: @escaping (Self.Output) -> Void) {
		let cancellable = sink { [weak object] in
			receiveValue($0)
			object?[keyPath: keyPath] = nil
		}
		object[keyPath: keyPath] = cancellable
	}

	func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, on object: Root) -> AnyCancellable {
		return sink {
			object[keyPath: keyPath] = $0
		}
	}

	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root) -> AnyCancellable {
		return sink { [weak object] in
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
