//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroAsync
import KokoroUtils

public typealias HttpClientProgress = UrlSessionDataTaskProgressPublisher.Output.Progress

private let detailedJsonDecodingErrorFactory = DetailedJsonDecodingErrorFactory()

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

public struct HttpClientResponse: ValueWith {
	public let statusCode: Int
	public let headers: [String: String]
	public let data: Data

	public init(statusCode: Int, headers: [String: String], data: Data) {
		self.statusCode = statusCode
		self.headers = headers
		self.data = data
	}
}

public protocol HttpClient {
	func requestPublisher(_ request: URLRequest) -> AnyPublisher<HttpClientResponse, Error>
	func requestProgressPublisher(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error>

	#if swift(>=5.6)
	func request(_ request: URLRequest) async throws -> HttpClientResponse
	func requestProgress(_ request: URLRequest) -> AnyAsyncSequence<HttpClientOutput<HttpClientResponse>>
	#endif
}

public extension HttpClient {
	func requestPublisher(_ request: URLRequest) -> AnyPublisher<HttpClientResponse, Error> {
		return self.requestProgressPublisher(request).unwrap()
	}

	#if swift(>=5.6)
	func request(_ request: URLRequest) async throws -> HttpClientResponse {
		for try await output in requestProgress(request) {
			switch output {
			case .sendProgress, .receiveProgress:
				break
			case let .output(output):
				return output
			}
		}
		fatalError("Sequence did not return an .output value.")
	}

	func requestProgress(_ request: URLRequest) -> AnyAsyncSequence<HttpClientOutput<HttpClientResponse>> {
		return requestProgressPublisher(request).asyncStream().eraseToAnyAsyncSequence()
	}
	#endif
}

public struct HttpClientUnallowedStatusCodeError: Hashable, Error {
	public let statusCode: Int

	public init(statusCode: Int) {
		self.statusCode = statusCode
	}
}

public extension AsyncSequence {
	func unwrap<OutputType>() async throws -> OutputType where Element == HttpClientOutput<OutputType> {
		for try await element in self {
			switch element {
			case .sendProgress, .receiveProgress:
				break
			case let .output(output):
				return output
			}
		}
		fatalError("Sequence did not return an .output value.")
	}
}

public extension Publisher {
	func unwrap<OutputType>() -> AnyPublisher<OutputType, Failure> where Output == HttpClientOutput<OutputType> {
		return filter {
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

public extension Publisher where Output == HttpClientOutput<HttpClientResponse> {
	func unwrapWithoutDecoding() -> AnyPublisher<Void, Failure> {
		return filter {
			switch $0 {
			case .output:
				return true
			default:
				return false
			}
		}
		.map {
			switch $0 {
			case .output:
				return ()
			default:
				fatalError("This should not happen")
			}
		}
		.eraseToAnyPublisher()
	}

	func decode<DecodableType, Decoder>(_ type: DecodableType.Type, via decoder: Decoder) -> AnyPublisher<HttpClientOutput<DecodableType>, Error> where DecodableType: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
		return tryMap {
			return try $0.map {
				do {
					return try decoder.decode(type, from: $0.data)
				} catch {
					if let error = error as? DecodingError {
						throw detailedJsonDecodingErrorFactory.detailedError(from: error, for: $0.data)
					} else {
						throw DetailedJsonDecodingError.undetailed(error)
					}
				}
			}
		}
		.eraseToAnyPublisher()
	}

	func decodeIfPresent<DecodableType, Decoder>(_ type: DecodableType.Type, via decoder: Decoder) -> AnyPublisher<HttpClientOutput<DecodableType?>, Error> where DecodableType: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
		return tryMap {
			return try $0.map {
				if $0.statusCode == 204 {
					return nil
				} else {
					do {
						return try decoder.decode(type, from: $0.data)
					} catch {
						if let error = error as? DecodingError {
							throw detailedJsonDecodingErrorFactory.detailedError(from: error, for: $0.data)
						} else {
							throw DetailedJsonDecodingError.undetailed(error)
						}
					}
				}
			}
		}
		.eraseToAnyPublisher()
	}

	func withAllowedOkStatusCodes() -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		return withAllowedStatusCodes(200 ..< 400)
	}

	func withAllowedStatusCodes<StatusCodeCollection>(_ allowedStatusCodes: StatusCodeCollection) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> where StatusCodeCollection: Collection, StatusCodeCollection.Element == Int {
		return tryMap {
			switch $0 {
			case let .output(response):
				if allowedStatusCodes.contains(response.statusCode) {
					return .output(response)
				} else {
					throw HttpClientUnallowedStatusCodeError(statusCode: response.statusCode)
				}
			case let .sendProgress(progress):
				return .sendProgress(progress)
			case let .receiveProgress(progress):
				return .receiveProgress(progress)
			}
		}
		.eraseToAnyPublisher()
	}
}
#endif
