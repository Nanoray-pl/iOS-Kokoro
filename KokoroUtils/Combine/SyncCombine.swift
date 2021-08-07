//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public enum SyncCombineError: Error {
	case timeout
}

public extension Publisher {
	func syncResult() -> Result<Output, Failure> {
		var value: Result<Output, Failure>!
		let semaphore = DispatchSemaphore(value: 0)
		_ = sinkResult {
			value = $0
			semaphore.signal()
		}

		semaphore.wait()
		return value
	}
}

public extension Publisher where Failure == Error {
	func syncResult(timeout: TimeInterval? = nil) -> Result<Output, Error> {
		var value: Result<Output, Error>!
		let semaphore = DispatchSemaphore(value: 0)
		_ = sinkResult {
			value = $0
			semaphore.signal()
		}

		if let timeout = timeout {
			switch semaphore.wait(timeout: .now() + timeout) {
			case .success:
				return value
			case .timedOut:
				return .failure(SyncCombineError.timeout)
			}
		} else {
			semaphore.wait()
			return value
		}
	}

	func syncFulfill(_ promise: (Result<Output, Error>) -> Void) {
		promise(syncResult())
	}
}

public extension Publisher where Failure == Never {
	func sync() -> Output {
		var value: Output!
		let semaphore = DispatchSemaphore(value: 0)
		_ = sink {
			value = $0
			semaphore.signal()
		}

		semaphore.wait()
		return value
	}

	func sync(timeout: TimeInterval) throws -> Output {
		var value: Output!
		let semaphore = DispatchSemaphore(value: 0)
		_ = sink {
			value = $0
			semaphore.signal()
		}

		switch semaphore.wait(timeout: .now() + timeout) {
		case .success:
			return value
		case .timedOut:
			throw SyncCombineError.timeout
		}
	}
}
#endif
