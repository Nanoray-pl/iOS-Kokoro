//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import Combine
import Foundation

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

	func syncResult(timeout: TimeInterval? = nil) -> Result<Output, Failure> {
		var value: Result<Output, Failure>!
		let semaphore = DispatchSemaphore(value: 0)
		_ = sinkResult {
			value = $0
			semaphore.signal()
		}

		if let timeout = timeout {
			_ = semaphore.wait(timeout: .now() + timeout)
		} else {
			semaphore.wait()
		}
		return value
	}

	func syncFulfill(_ promise: (Result<Output, Failure>) -> Void) {
		promise(syncResult())
	}
}
