//
//  Created on 08/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public final class ErrorSimulationContext {
	public enum Occurence: Hashable {
		case never
		case always
		case oneIn(_ cycleLength: Int)
		case chance(_ chance: Double)
	}

	private var requestCounter = 0

	public var errorOccurence: Occurence {
		didSet {
			if case .oneIn = errorOccurence {
				requestCounter = 0
			}
		}
	}

	public init(errorOccurence: Occurence) {
		self.errorOccurence = errorOccurence
	}

	public func updateCounterAndReturnIfShouldSucceed() -> Bool {
		switch errorOccurence {
		case .never:
			return true
		case .always:
			return false
		case let .chance(chance):
			return Double.random(in: 0 ..< 1) >= chance
		case let .oneIn(cycleLength):
			requestCounter = (requestCounter + 1) % cycleLength
			return requestCounter != 0
		}
	}
}

public final class ErrorSimulatingHttpClient: HttpClient {
	public enum Mode {
		case insteadOfRequest, replacingResponse
	}

	private let wrapped: HttpClient
	public var context: ErrorSimulationContext
	public var errorFactory: () -> URLError
	public var mode: Mode

	public init(wrapping wrapped: HttpClient, mode: Mode, context: ErrorSimulationContext, errorFactory: @autoclosure @escaping () -> URLError) {
		self.wrapped = wrapped
		self.mode = mode
		self.context = context
		self.errorFactory = errorFactory
	}

	public func requestProgressPublisher(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		var wrapped: HttpClient! = self.wrapped
		return Deferred { [mode, context, errorFactory] () -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> in
			if context.updateCounterAndReturnIfShouldSucceed() {
				let publisher = wrapped.requestProgressPublisher(request)
				wrapped = nil
				return publisher
			} else {
				switch mode {
				case .insteadOfRequest:
					return Fail(error: errorFactory())
						.eraseToAnyPublisher()
				case .replacingResponse:
					let publisher = wrapped.requestProgressPublisher(request)
					wrapped = nil
					return publisher
						.mapError { _ in errorFactory() }
						.flatMap { _ in
							return Fail(error: errorFactory())
								.eraseToAnyPublisher()
						}
						.eraseToAnyPublisher()
				}
			}
		}
		.eraseToAnyPublisher()
	}
}

public extension HttpClient {
	func simulatingErrors(mode: ErrorSimulatingHttpClient.Mode, context: ErrorSimulationContext, errorFactory: @autoclosure @escaping () -> URLError) -> HttpClient {
		return ErrorSimulatingHttpClient(wrapping: self, mode: mode, context: context, errorFactory: errorFactory())
	}
}
#endif
