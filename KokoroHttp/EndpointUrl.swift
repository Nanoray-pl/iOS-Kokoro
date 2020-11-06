//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public struct EndpointUrl<PathParameters, QueryParameters> {
	public let url: URL

	public init(_ url: URL) {
		self.url = url
	}

	private func append(_ item: URLQueryItem, to components: inout URLComponents) {
		var queryItems = components.queryItems ?? []
		queryItems.append(item)
		components.queryItems = queryItems
	}

	private func dictionary<E: Encodable>(from encodable: E) throws -> [String: Any] {
		let data = try JSONEncoder().encode(encodable)
		return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
	}

	private func urlByAddingQueryParameters<E: Encodable>(_ queryParameters: E, to url: URL) throws -> URL {
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		for (key, value) in try dictionary(from: queryParameters) {
			append(URLQueryItem(name: key, value: String(describing: value)), to: &components)
		}
		return components.url!
	}

	private func urlByReplacingPathParameters<E: Encodable>(_ pathParameters: E, in url: URL) throws -> URL {
		var absolutePath = url.absoluteString.replacingOccurrences(of: "%7B", with: "{").replacingOccurrences(of: "%7D", with: "}")
		for (key, value) in try dictionary(from: pathParameters) {
			absolutePath = absolutePath.replacingOccurrences(of: "{\(key)}", with: String(describing: value))
		}
		return URL(string: absolutePath)!
	}
}

public extension EndpointUrl where PathParameters == Void, QueryParameters == Void {
	func create() -> URL {
		return url
	}
}

public extension EndpointUrl where PathParameters == Void, QueryParameters: Encodable {
	func create(queryParameters: QueryParameters) throws -> URL {
		return try urlByAddingQueryParameters(queryParameters, to: url)
	}
}

public extension EndpointUrl where PathParameters: Encodable, QueryParameters == Void {
	func create(pathParameters: PathParameters) throws -> URL {
		return try urlByReplacingPathParameters(pathParameters, in: url)
	}
}

public extension EndpointUrl where PathParameters: Encodable, QueryParameters: Encodable {
	func create(pathParameters: PathParameters, queryParameters: QueryParameters) throws -> URL {
		return try urlByAddingQueryParameters(queryParameters, to: try urlByReplacingPathParameters(pathParameters, in: url))
	}
}
#endif
