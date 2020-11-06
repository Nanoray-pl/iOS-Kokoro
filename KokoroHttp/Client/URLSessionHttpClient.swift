//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class URLSessionHttpClient: HttpClient {
	private enum ResponseError: Error {
		case unexpectedStatusCode(_ statusCode: Int, responseString: String)
	}

	private let session: URLSession
	private let decoder: JSONDecoder
	private let allowedStatusCodes: Set<Int>

	init(session: URLSession, decoder: JSONDecoder, allowedStatusCodes: Set<Int> = Set(200 ..< 400)) {
		self.session = session
		self.decoder = decoder
		self.allowedStatusCodes = allowedStatusCodes
	}

	private func publisher(for request: URLRequest) -> AnyPublisher<HttpClientOutput<(data: Data, response: URLResponse)>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.tryMap { [allowedStatusCodes] in
				switch $0 {
				case let .output(data, response):
					if let response = response as? HTTPURLResponse {
						if allowedStatusCodes.contains(response.statusCode) {
							return .output((data: data, response: response))
						} else {
							throw ResponseError.unexpectedStatusCode(response.statusCode, responseString: String(decoding: data, as: UTF8.self))
						}
					} else {
						return .output((data: data, response: response))
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

	public func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error> {
		return publisher(for: request)
			.tryMap { [decoder] in
				return try $0.map { data, response in
					if let response = response as? HTTPURLResponse, response.statusCode == 204 {
						return nil
					} else {
						return try decoder.decode(Output.self, from: data)
					}
				}
			}
			.eraseToAnyPublisher()
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		return publisher(for: request)
			.tryMap { [decoder] in try $0.map { try decoder.decode(Output.self, from: $0.data) } }
			.eraseToAnyPublisher()
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return publisher(for: request)
			.map { $0.map { _ in () } }
			.eraseToAnyPublisher()
	}
}
#endif
