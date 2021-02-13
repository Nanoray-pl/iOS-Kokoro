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

public struct HttpClientResponse {
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
	func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error>
}
#endif
