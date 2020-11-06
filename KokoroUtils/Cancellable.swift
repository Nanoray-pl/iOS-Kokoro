//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol CancellableProtocol: class {
	func cancel()
}

public class FakeCancellable: CancellableProtocol {
	public func cancel() {
		// do nothing
	}
}

public class ReplaceableCancellable: CancellableProtocol {
	public var cancellable: CancellableProtocol?

	public init(wrapping cancellable: CancellableProtocol? = nil) {
		self.cancellable = cancellable
	}

	public func cancel() {
		cancellable?.cancel()
	}
}

@propertyWrapper
public struct Cancellable<SpecificCancellable: CancellableProtocol> {
	private var value: SpecificCancellable?

	public init(wrappedValue value: SpecificCancellable?) {
		self.value = value
	}

	public var wrappedValue: SpecificCancellable? {
		get {
			return value
		}
		set {
			value?.cancel()
			value = newValue
		}
	}
}

#if canImport(Foundation)
import Foundation

extension DispatchWorkItem: CancellableProtocol {}
extension URLSessionTask: CancellableProtocol {}

extension Timer: CancellableProtocol {
	public func cancel() {
		invalidate()
	}
}
#endif

#if canImport(Combine)
import Combine

extension Combine.AnyCancellable: CancellableProtocol {}
#endif
