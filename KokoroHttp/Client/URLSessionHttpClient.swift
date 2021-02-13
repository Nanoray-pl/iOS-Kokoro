//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class URLSessionHttpClient: HttpClient {
	public enum ResponseError: Error {
		case unexpectedStatusCode(_ statusCode: Int, responseString: String)
	}

	private let session: URLSession
	private let allowedStatusCodes: Set<Int>

	private lazy var detailedJsonDecodingErrorFactory = DetailedJsonDecodingErrorFactory()

	public init(session: URLSession, allowedStatusCodes: Set<Int> = Set(200 ..< 400)) {
		self.session = session
		self.allowedStatusCodes = allowedStatusCodes
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.tryMap { [allowedStatusCodes] in
				switch $0 {
				case let .output(data, response):
					if let response = response as? HTTPURLResponse {
						if allowedStatusCodes.contains(response.statusCode) {
							return .output(.init(statusCode: response.statusCode, headers: response.allHeaderFields as! [String: String], data: data))
						} else {
							throw ResponseError.unexpectedStatusCode(response.statusCode, responseString: String(decoding: data, as: UTF8.self))
						}
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
