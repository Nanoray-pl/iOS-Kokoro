//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine
import KokoroUtils

public extension Publisher {
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
		let lock: Lock = DefaultLock()
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
}
#endif
