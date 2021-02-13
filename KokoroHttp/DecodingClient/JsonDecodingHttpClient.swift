//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class JsonDecodingHttpClient: DecodingHttpClient {
	private let wrapped: HttpClient
	private let decoder: JSONDecoder

	private lazy var detailedJsonDecodingErrorFactory = DetailedJsonDecodingErrorFactory()

	public init(wrapping wrapped: HttpClient, decoder: JSONDecoder = .init()) {
		self.wrapped = wrapped
		self.decoder = decoder
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

	public func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error> {
		let decodeClosure: (_ data: Data) throws -> Output = self.decodeClosure()
		return wrapped.request(request)
			.tryMap {
				return try $0.map { response in
					if response.statusCode == 204 {
						return nil
					} else {
						return try decodeClosure(response.data)
					}
				}
			}
			.eraseToAnyPublisher()
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		let decodeClosure: (_ data: Data) throws -> Output = self.decodeClosure()
		return wrapped.request(request)
			.tryMap { try $0.map { try decodeClosure($0.data) } }
			.eraseToAnyPublisher()
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return wrapped.request(request)
			.map { $0.map { _ in () } }
			.eraseToAnyPublisher()
	}
}

public extension HttpClient {
	func jsonDecoding(_ decoder: JSONDecoder = .init()) -> DecodingHttpClient {
		return JsonDecodingHttpClient(wrapping: self, decoder: decoder)
	}
}
#endif
