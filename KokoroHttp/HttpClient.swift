//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public enum HttpClientOutput<Output> {
	case progress(_ progress: Progress)
	case output(_ output: Output)

	public typealias Progress = UrlSessionDataTaskProgressPublisher.Output.Progress
}

public protocol HttpClient {
	func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error>
	func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error>
	func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error>
}

public extension HttpClient {
	func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<Output?, Error> {
		let wrapped: AnyPublisher<HttpClientOutput<Output?>, Error> = requestOptional(request)
		return wrapped
			.filter {
				switch $0 {
				case .output:
					return true
				default:
					return false
				}
			}
			.map {
				switch $0 {
				case let .output(output):
					return output
				default:
					fatalError("This should not happen")
				}
			}
			.eraseToAnyPublisher()
	}

	func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<Output, Error> {
		let wrapped: AnyPublisher<HttpClientOutput<Output>, Error> = self.request(request)
		return wrapped
			.filter {
				switch $0 {
				case .output:
					return true
				default:
					return false
				}
			}
			.map {
				switch $0 {
				case let .output(output):
					return output
				default:
					fatalError("This should not happen")
				}
			}
			.eraseToAnyPublisher()
	}

	func request(_ request: URLRequest) -> AnyPublisher<Void, Error> {
		let wrapped: AnyPublisher<HttpClientOutput<Void>, Error> = self.request(request)
		return wrapped
			.filter {
				switch $0 {
				case .output:
					return true
				default:
					return false
				}
			}
			.map {
				switch $0 {
				case let .output(output):
					return output
				default:
					fatalError("This should not happen")
				}
			}
			.eraseToAnyPublisher()
	}
}

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
