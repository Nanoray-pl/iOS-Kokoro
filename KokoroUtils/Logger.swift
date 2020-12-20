//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum LogLevel: String, CaseIterable, Comparable {
	/// Used for logging big chunks of data for debugging purposes (hidden by default).
	case verbose

	/// Used for logging smaller chunks (mostly singular lines) of data for debugging purposes.
	case debug

	/// Used for logging (successful) events.
	case info

	/// Used for logging errors, which can be handled gracefully.
	case warning

	/// Used for logging errors, which cannot be handled gracefully and which will break the flow of the app, but not crash it.
	case error

	public var symbol: String? {
		switch self {
		case .verbose:
			return nil
		case .debug:
			return "⚫️"
		case .info:
			return "🔵"
		case .warning:
			return "🟡"
		case .error:
			return "🔴"
		}
	}

	public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
		return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
	}
}

public protocol LoggerFactory {
	func createLogger(name: String, level: LogLevel) -> Logger
}

public extension LoggerFactory {
	func createLogger(name: String = #file, level: LogLevel) -> Logger {
		return createLogger(name: name, level: level)
	}

	func createLogger<T>(for type: T.Type, level: LogLevel) -> Logger {
		return createLogger(name: String(describing: type), level: level)
	}
}

public protocol Logger {
	var level: LogLevel { get set }

	func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, function: String, line: Int)
}

public extension Logger {
	func verbose(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
		log(.verbose, message(), file: file, function: function, line: line)
	}

	func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
		log(.debug, message(), file: file, function: function, line: line)
	}

	func info(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
		log(.info, message(), file: file, function: function, line: line)
	}

	func warning(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
		log(.warning, message(), file: file, function: function, line: line)
	}

	func error(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
		log(.error, message(), file: file, function: function, line: line)
	}

	func log(_ level: LogLevel, _ message: @autoclosure () -> String = "", sourceFile: String = #file, sourceFunction: String = #function, sourceLine: Int = #line) {
		log(level, message(), file: sourceFile, function: sourceFunction, line: sourceLine)
	}
}

#if canImport(os)
import os.log

public class OSLogLoggerFactory: LoggerFactory {
	public init() {}

	public func createLogger(name: String, level: LogLevel) -> Logger {
		return OSLogLogger(logger: OSLog(subsystem: name, category: name), name: name, initialLevel: level)
	}

	private class OSLogLogger: Logger {
		private let logger: OSLog
		private let name: String

		var level: LogLevel

		init(logger: OSLog, name: String, initialLevel: LogLevel) {
			self.name = name
			self.logger = logger
			level = initialLevel
		}

		private func identifier(file: String, function: String, line: Int) -> String {
			return "\(file.split(separator: "/").last!):\(function):\(line)"
		}

		func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, function: String, line: Int) {
			guard level >= self.level else { return }

			let builtMessage = message()
			let builtMessageWithPrefix = builtMessage.isEmpty ? "" : ": \(builtMessage)"
			let finalMessage = "\(identifier(file: file, function: function, line: line))\(builtMessageWithPrefix)"

			os_log("%@[%@] %@", type: Self.osLogType(for: level), level.symbol ?? "", name, finalMessage)
		}

		private static func osLogType(for level: LogLevel) -> OSLogType {
			switch level {
			case .verbose:
				return .debug
			case .debug:
				return .debug
			case .info:
				return .info
			case .warning:
				return .info
			case .error:
				return .error
			}
		}
	}
}
#endif

#if canImport(Combine)
import Combine

public extension Publisher {
	func logging(to logger: Logger, file: String = #file, function: String = #function, line: Int = #line, name: String, outputLogLevel: LogLevel = .info, failureLogLevel: LogLevel = .warning, subscribeLogLevel: LogLevel = .debug, outputMapper: @escaping (Output) -> String = { "\($0)" }) -> Publishers.HandleEvents<Self> {
		return handleEvents(
			receiveSubscription: { _ in logger.log(subscribeLogLevel, "\(name) initiated", file: file, function: function, line: line) },
			receiveOutput: { logger.log(outputLogLevel, "\(name): \(outputMapper($0))", file: file, function: function, line: line) },
			receiveCompletion: {
				if case let Subscribers.Completion.failure(error) = $0 {
					logger.log(failureLogLevel, "\(name): \(error)", file: file, function: function, line: line)
				}
			}
		)
	}
}
#endif
