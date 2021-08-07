//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class CancelBag {
	private var cancellableSet = Set<AnyCancellable>()
	private let lock = FoundationLock()

	public init() {}

	public func insert(_ cancellable: AnyCancellable) {
		lock.acquireAndRun {
			_ = cancellableSet.insert(cancellable)
		}
	}

	public func remove(_ cancellable: AnyCancellable) {
		lock.acquireAndRun {
			_ = cancellableSet.remove(cancellable)
		}
	}
}

public extension Publisher {
	@discardableResult
	func sinkResult(storingIn bag: CancelBag, _ closure: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
		var capturedCancellable: AnyCancellable?
		let cancellable = onCancel {
			if let cancellable = capturedCancellable {
				bag.remove(cancellable)
				capturedCancellable = nil
			}
		}
		.sinkResult {
			if let cancellable = capturedCancellable {
				bag.remove(cancellable)
				capturedCancellable = nil
			}
			closure($0)
		}
		capturedCancellable = cancellable

		bag.insert(cancellable)
		return cancellable
	}

	@discardableResult
	func sink(storingIn bag: CancelBag, receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void, receiveValue: @escaping (Self.Output) -> Void) -> AnyCancellable {
		var capturedCancellable: AnyCancellable?
		let cancellable = onCancel {
			if let cancellable = capturedCancellable {
				bag.remove(cancellable)
				capturedCancellable = nil
			}
		}
		.sink(receiveCompletion: {
			if let cancellable = capturedCancellable {
				bag.remove(cancellable)
				capturedCancellable = nil
			}
			receiveCompletion($0)
		}, receiveValue: receiveValue)
		capturedCancellable = cancellable

		bag.insert(cancellable)
		return cancellable
	}
}

public extension Publisher where Failure == Never {
	@discardableResult
	func sink(storingIn bag: CancelBag, receiveValue: @escaping (Self.Output) -> Void) -> AnyCancellable {
		return sink(storingIn: bag, receiveCompletion: { _ in }, receiveValue: receiveValue)
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

	@discardableResult
	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, onWeak object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}

	@discardableResult
	func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output?>, onWeak object: Root, storingIn bag: CancelBag) -> AnyCancellable {
		return sink(storingIn: bag) { [weak object] in
			object?[keyPath: keyPath] = $0
		}
	}
}
#endif
