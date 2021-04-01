//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class URLSessionHttpClient: HttpClient {
	private let session: URLSession

	public init(session: URLSession) {
		self.session = session
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.tryMap {
				switch $0 {
				case let .output(data, response):
					if let response = response as? HTTPURLResponse {
						return .output(.init(statusCode: response.statusCode, headers: response.allHeaderFields as! [String: String], data: data))
					} else {
						fatalError("Cannot handle non-HTTP response")
					}
				case let .sendProgress(progress):
					return .sendProgress(progress)
				case let .receiveProgress(progress):
					return .receiveProgress(progress)
				}
			}
			.mapError { $0 as Error }
			.eraseToAnyPublisher()
	}
}
#endif
