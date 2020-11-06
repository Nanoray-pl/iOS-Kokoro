//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation
import KokoroUtils

public enum HttpMethod: String {
	case get = "GET"
	case put = "PUT"
	case post = "POST"
	case delete = "DELETE"
	case head = "HEAD"
	case options = "OPTIONS"
	case trace = "TRACE"
	case connect = "CONNECT"
}

public protocol HttpRequestBuilder {
	func buildRequest(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any]) -> URLRequest

	func buildRequest<Body, BodyEncoder>(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any], body: Body, bodyEncoder: BodyEncoder) throws -> URLRequest where BodyEncoder: HttpBodyEncoder, BodyEncoder.Input == Body
}

public extension HttpRequestBuilder {
	func with(urlParameters: [String: Any]) -> HttpRequestBuilder {
		return HttpRequestBuilderWithParameters(wrapping: self, urlParameters: urlParameters, headers: [:])
	}

	func with(headers: [String: Any]) -> HttpRequestBuilder {
		return HttpRequestBuilderWithParameters(wrapping: self, urlParameters: [:], headers: headers)
	}

	func buildRequest(method: HttpMethod, url: URL, urlParameters: [String: Any] = [:], headers: [String: Any] = [:]) -> URLRequest {
		return buildRequest(method: method, url: url, urlParameters: urlParameters, headers: headers)
	}

	func buildRequest<Body, BodyEncoder>(method: HttpMethod, url: URL, urlParameters: [String: Any] = [:], headers: [String: Any] = [:], body: Body, bodyEncoder: BodyEncoder) throws -> URLRequest where BodyEncoder: HttpBodyEncoder, BodyEncoder.Input == Body {
		return try buildRequest(method: method, url: url, urlParameters: urlParameters, headers: headers, body: body, bodyEncoder: bodyEncoder)
	}

	func buildRequest<Body: Encodable>(method: HttpMethod, url: URL, urlParameters: [String: Any] = [:], headers: [String: Any] = [:], body: Body, bodyEncoder: JSONEncoder = .init()) throws -> URLRequest {
		return try buildRequest(method: method, url: url, urlParameters: urlParameters, headers: headers, body: body, bodyEncoder: JsonHttpBodyEncoder<Body>(encoder: bodyEncoder))
	}
}

public class DefaultHttpRequestBuilder: HttpRequestBuilder {
	public init() {}

	public func buildRequest(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any]) -> URLRequest {
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		for (key, value) in urlParameters {
			append(URLQueryItem(name: key, value: String(describing: value)), to: &components)
		}
		var request = URLRequest(url: components.url!)
		request.httpMethod = method.rawValue
		for (key, value) in headers {
			request.setValue(String(describing: value), forHTTPHeaderField: key)
		}
		return request
	}

	public func buildRequest<Body, BodyEncoder>(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any], body: Body, bodyEncoder: BodyEncoder) throws -> URLRequest where BodyEncoder: HttpBodyEncoder, BodyEncoder.Input == Body {
		var request = buildRequest(method: method, url: url, urlParameters: urlParameters, headers: headers)
		let encoded = try bodyEncoder.encode(body)
		request.setValue(encoded.contentType, forHTTPHeaderField: "Content-Type")
		request.httpBody = encoded.body
		return request
	}

	private func append(_ item: URLQueryItem, to components: inout URLComponents) {
		var queryItems = components.queryItems ?? []
		queryItems.append(item)
		components.queryItems = queryItems
	}
}

public class HttpRequestBuilderWithParameters: HttpRequestBuilder {
	private let wrapped: HttpRequestBuilder
	private let urlParameters: [String: Any]
	private let headers: [String: Any]

	init(wrapping wrapped: HttpRequestBuilder, urlParameters: [String: Any], headers: [String: Any]) {
		self.wrapped = wrapped
		self.urlParameters = urlParameters
		self.headers = headers
	}

	public func buildRequest(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any]) -> URLRequest {
		return wrapped.buildRequest(
			method: method,
			url: url,
			urlParameters: self.urlParameters.merging(urlParameters, withMergePolicy: .overwrite),
			headers: self.headers.merging(headers, withMergePolicy: .overwrite)
		)
	}

	public func buildRequest<Body, BodyEncoder>(method: HttpMethod, url: URL, urlParameters: [String: Any], headers: [String: Any], body: Body, bodyEncoder: BodyEncoder) throws -> URLRequest where BodyEncoder: HttpBodyEncoder, BodyEncoder.Input == Body {
		return try wrapped.buildRequest(
			method: method,
			url: url,
			urlParameters: self.urlParameters.merging(urlParameters, withMergePolicy: .overwrite),
			headers: self.headers.merging(headers, withMergePolicy: .overwrite),
			body: body,
			bodyEncoder: bodyEncoder
		)
	}
}
#endif
