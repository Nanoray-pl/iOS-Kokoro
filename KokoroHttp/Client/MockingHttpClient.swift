//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class MockingHttpClient: HttpClient {
	public typealias Mock = (URLRequest) -> Result<HttpClientResponse, Error>?

	private let wrapped: HttpClient?
	public var mocks: [Mock]

	public init(wrapping wrapped: HttpClient? = nil, mocks: [Mock]) {
		self.wrapped = wrapped
		self.mocks = mocks
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		if let result = mocks.compactMapFirst({ $0(request) }) { return result.map { .output($0) }.publisher.eraseToAnyPublisher() }
		guard let wrapped = wrapped else { fatalError("Unhandled HTTP request") }
		return wrapped.request(request)
	}
}

public extension HttpClient {
	func mocking(_ mocks: [MockingHttpClient.Mock]) -> HttpClient {
		return MockingHttpClient(wrapping: self, mocks: mocks)
	}
}
#endif
