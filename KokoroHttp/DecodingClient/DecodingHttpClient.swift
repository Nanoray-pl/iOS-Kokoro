//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public protocol DecodingHttpClient {
	func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error>
	func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error>
	func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error>
}

public extension DecodingHttpClient {
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
#endif
