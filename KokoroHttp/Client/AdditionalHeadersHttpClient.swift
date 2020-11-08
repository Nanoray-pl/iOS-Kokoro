//
//  Created on 08/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroUtils

public class AdditionalHeadersHttpClient: HttpClient {
	private let wrapped: HttpClient
	public var headers: [String: String]
	private let mergePolicy: DictionaryMergePolicy

	public init(wrapping wrapped: HttpClient, headers: [String: String], withMergePolicy mergePolicy: DictionaryMergePolicy = .keepCurrent) {
		self.wrapped = wrapped
		self.headers = headers
		self.mergePolicy = mergePolicy
	}

	private func modifiedRequest(_ request: URLRequest) -> URLRequest {
		return request.with {
			$0.allHTTPHeaderFields = ($0.allHTTPHeaderFields ?? [:]).merging(headers, withMergePolicy: mergePolicy)
		}
	}

	public func requestOptional<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output?>, Error> {
		return wrapped.requestOptional(modifiedRequest(request))
	}

	public func request<Output: Decodable>(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Output>, Error> {
		return wrapped.request(modifiedRequest(request))
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<Void>, Error> {
		return wrapped.request(modifiedRequest(request))
	}
}

public extension HttpClient {
	func withAdditionalHeaders(_ headers: [String: String], withMergePolicy mergePolicy: DictionaryMergePolicy = .keepCurrent) -> HttpClient {
		return AdditionalHeadersHttpClient(wrapping: self, headers: headers, withMergePolicy: mergePolicy)
	}
}
#endif