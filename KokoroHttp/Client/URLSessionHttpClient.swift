//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class URLSessionHttpClient: HttpClient {
	private let session: URLSession
	private let decoder: JSONDecoder

	init(session: URLSession, decoder: JSONDecoder) {
		self.session = session
		self.decoder = decoder
	}

	public func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.tryMap { [decoder] in
				switch $0 {
				case let .output(data, response):
					if let response = response as? HTTPURLResponse, response.statusCode == 204 {
						return .output(nil)
					} else {
						return .output(try decoder.decode(Output.self, from: data))
					}
				case let .progress(progress):
					return .progress(progress)
				}
			}
			.eraseToAnyPublisher()
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.tryMap { [decoder] in
				switch $0 {
				case let .output(data, _):
					return .output(try decoder.decode(Output.self, from: data))
				case let .progress(progress):
					return .progress(progress)
				}
			}
			.eraseToAnyPublisher()
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return session.dataTaskProgressPublisher(for: request)
			.map {
				switch $0 {
				case .output:
					return .output(())
				case let .progress(progress):
					return .progress(progress)
				}
			}
			.mapError { $0 as Error }
			.eraseToAnyPublisher()
	}
}
#endif
