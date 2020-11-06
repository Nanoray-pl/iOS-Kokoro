//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public typealias HttpClientProgress = UrlSessionDataTaskProgressPublisher.Output.Progress

public enum HttpClientOutput<Output> {
	case sendProgress(_ progress: HttpClientProgress)
	case receiveProgress(_ progress: HttpClientProgress)
	case output(_ output: Output)

	public func map<NewOutput>(_ mappingFunction: (Output) throws -> NewOutput) rethrows -> HttpClientOutput<NewOutput> {
		switch self {
		case let .sendProgress(progress):
			return .sendProgress(progress)
		case let .receiveProgress(progress):
			return .receiveProgress(progress)
		case let .output(output):
			return .output(try mappingFunction(output))
		}
	}
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
#endif
