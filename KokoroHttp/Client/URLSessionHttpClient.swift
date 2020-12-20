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

	private lazy var detailedJsonDecodingErrorFactory = DetailedJsonDecodingErrorFactory()

	public init(session: URLSession, decoder: JSONDecoder, allowedStatusCodes: Set<Int> = Set(200 ..< 400)) {
		self.session = session
		self.decoder = decoder
		self.allowedStatusCodes = allowedStatusCodes
	}

	private func decodeClosure<Output: Decodable>() -> ((_ data: Data) throws -> Output) {
		return { [decoder, detailedJsonDecodingErrorFactory] data in
			do {
				return try decoder.decode(Output.self, from: data)
			} catch {
				if let error = error as? DecodingError {
					throw detailedJsonDecodingErrorFactory.detailedError(from: error, for: data)
				} else {
					throw DetailedJsonDecodingError.undetailed(error)
				}
			}
		}
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
		let decodeClosure: (_ data: Data) throws -> Output = self.decodeClosure()
		return publisher(for: request)
			.tryMap {
				return try $0.map { data, response in
					if let response = response as? HTTPURLResponse, response.statusCode == 204 {
						return nil
					} else {
						return try decodeClosure(data)
					}
				}
			}
			.eraseToAnyPublisher()
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		let decodeClosure: (_ data: Data) throws -> Output = self.decodeClosure()
		return publisher(for: request)
			.tryMap { try $0.map { try decodeClosure($0.data) } }
			.eraseToAnyPublisher()
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return publisher(for: request)
			.map { $0.map { _ in () } }
			.eraseToAnyPublisher()
	}
}
#endif
