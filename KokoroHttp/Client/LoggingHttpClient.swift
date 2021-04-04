//
//  Created on 01/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import Combine
import Foundation
import KokoroUtils

public class LoggingHttpClient: HttpClient {
	public typealias RequestId = UUID

	public enum LogLineType {
		public enum Part {
			case baseInfo, headers, body, progress
		}

		case request(_ part: Part)
		case response(_ part: Part)
		case error
		case cancel
	}

	public struct Configuration {
		public typealias RequestCallback = (RequestId, URLRequest) -> Void
		public typealias OutputCallback = (RequestId, URLRequest, HttpClientOutput<HttpClientResponse>) -> Void
		public typealias ErrorCallback = (RequestId, URLRequest, Error) -> Void
		public typealias CancelCallback = (RequestId, URLRequest) -> Void

		private static let binaryOnlyBytes: Set<UInt8> = Set(0x00 ... 0x1F).subtracting([0x09, 0x10, 0x0D])

		public let request: RequestCallback?
		public let output: OutputCallback?
		public let error: ErrorCallback?
		public let cancel: CancelCallback?

		public init(request: RequestCallback? = nil, output: OutputCallback? = nil, error: ErrorCallback? = nil, cancel: CancelCallback? = nil) {
			self.request = request
			self.output = output
			self.error = error
			self.cancel = cancel
		}

		public init(maxRequestLength: Int? = nil, maxOutputLength: Int? = nil, loggingClosure: @escaping (_ logLineType: LogLineType, _ line: () -> String) -> Void) {
			self.init(
				request: { requestId, request in
					guard let httpMethod = request.httpMethod, let url = request.url else { return }
					loggingClosure(.request(.baseInfo)) { ">>> [\(requestId)] HTTP \(httpMethod.uppercased()) \(url)" }
					loggingClosure(.request(.headers)) { ">>> [\(requestId)] \(Self.logHeaders(request.allHTTPHeaderFields))" }
					loggingClosure(.request(.body)) { ">>> [\(requestId)] \(Self.logBody(request.httpBody, maxLength: maxRequestLength))" }
				},
				output: { requestId, request, output in
					switch output {
					case let .sendProgress(progress):
						switch progress {
						case let .determinate(processedByteCount, expectedByteCount) where processedByteCount > 0 && expectedByteCount > 0:
							loggingClosure(.request(.progress)) { ">>> [\(requestId)] Send progress: \(processedByteCount)/\(expectedByteCount) byte(s) (\(Int(Double(processedByteCount) / Double(expectedByteCount) * 100))%)" }
						case let .indeterminate(processedByteCount) where processedByteCount > 0:
							loggingClosure(.request(.progress)) { ">>> [\(requestId)] Send progress: \(processedByteCount) byte(s)" }
						case .determinate, .indeterminate:
							break
						}
					case let .receiveProgress(progress):
						switch progress {
						case let .determinate(processedByteCount, expectedByteCount) where processedByteCount > 0 && expectedByteCount > 0:
							loggingClosure(.request(.progress)) { "<<< [\(requestId)] Receive progress: \(processedByteCount)/\(expectedByteCount) byte(s) (\(Int(Double(processedByteCount) / Double(expectedByteCount) * 100))%)" }
						case let .indeterminate(processedByteCount) where processedByteCount > 0:
							loggingClosure(.request(.progress)) { "<<< [\(requestId)] Receive progress: \(processedByteCount) byte(s)" }
						case .determinate, .indeterminate:
							break
						}
					case let .output(output):
						guard let httpMethod = request.httpMethod, let url = request.url else { return }
						loggingClosure(.response(.baseInfo)) { "<<< [\(requestId)] HTTP \(output.statusCode) for \(httpMethod.uppercased()) \(url)" }
						loggingClosure(.response(.headers)) { "<<< [\(requestId)] \(Self.logHeaders(output.headers))" }
						loggingClosure(.response(.body)) { "<<< [\(requestId)] \(Self.logBody(output.data, maxLength: maxOutputLength))" }
					}
				},
				error: { requestId, _, error in
					loggingClosure(.error) { "<<< [\(requestId)] Error: \(error)" }
				},
				cancel: { requestId, _ in
					loggingClosure(.cancel) { "<<< [\(requestId)] Cancelled" }
				}
			)
		}

		private static func logHeaders(_ headers: [String: String]?) -> String {
			var lines = [String]()
			if let headers = headers.nonEmpty {
				lines.append("Headers:")
				headers.forEach { key, value in lines.append("\t\(key): \(value)") }
			} else {
				lines.append("Headers: <none>")
			}
			return lines.joined(separator: "\n")
		}

		private static func logBody(_ data: Data?, maxLength: Int?) -> String {
			var lines = [String]()
			if let body = data.nonEmpty {
				let outputSummaryOnly: Bool
				if let maxLength = maxLength, body.count > maxLength {
					outputSummaryOnly = true
				} else if body.contains(where: { Self.binaryOnlyBytes.contains($0) }) {
					outputSummaryOnly = true
				} else {
					outputSummaryOnly = false
				}

				if !outputSummaryOnly, let bodyText = String(data: body, encoding: .utf8) {
					lines.append("Data: UTF-8 text")
					lines.append("==========")
					lines.append(bodyText)
					lines.append("==========")
				} else {
					lines.append("Data: (\(body.count) byte(s))")
				}
			} else {
				lines.append("Data: <none>")
			}
			return lines.joined(separator: "\n")
		}
	}

	private let wrapped: HttpClient
	private let configuration: Configuration

	public init(wrapping wrapped: HttpClient, configuration: Configuration) {
		self.wrapped = wrapped
		self.configuration = configuration
	}

	public func request(_ request: URLRequest) -> AnyPublisher<HttpClientOutput<HttpClientResponse>, Error> {
		let requestId = RequestId()
		var finished = false
		return wrapped.request(request)
			.onStart { [configuration] in configuration.request?(requestId, request) }
			.onOutput { [configuration] in
				configuration.output?(requestId, request, $0)
				switch $0 {
				case .output:
					finished = true
				case .sendProgress, .receiveProgress:
					break
				}
			}
			.onError { [configuration] in
				configuration.error?(requestId, request, $0)
				finished = true
			}
			.onCancel { [configuration] in
				if !finished {
					configuration.cancel?(requestId, request)
				}
			}
			.eraseToAnyPublisher()
	}
}

public extension HttpClient {
	func logging(configuration: LoggingHttpClient.Configuration) -> HttpClient {
		return LoggingHttpClient(wrapping: self, configuration: configuration)
	}
}
