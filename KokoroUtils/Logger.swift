//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import os.log

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

	var symbol: String? {
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

	func log(_ level: LogLevel, _ message: @autoclosure () -> String, _ identifier: CodeIdentifier)
}

public extension Logger {
	func verbose(_ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(.verbose, message(), identifier)
	}

	func debug(_ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(.debug, message(), identifier)
	}

	func info(_ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(.info, message(), identifier)
	}

	func warning(_ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(.warning, message(), identifier)
	}

	func error(_ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(.error, message(), identifier)
	}

	func log(_ level: LogLevel, _ message: @autoclosure () -> String, _ identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line)) {
		log(level, message(), identifier)
	}
}

class OSLogLoggerFactory: LoggerFactory {
	func createLogger(name: String, level: LogLevel) -> Logger {
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

		func log(_ level: LogLevel, _ message: @autoclosure () -> String, _ identifier: CodeIdentifier) {
			guard level >= self.level else { return }

			let builtMessage = message()
			let builtMessageWithPrefix = builtMessage.isEmpty ? "" : ": \(builtMessage)"
			let finalMessage = "\(identifier.stringRepresentation)\(builtMessageWithPrefix)"

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

#if canImport(Combine)
import Combine

public extension Publisher {
	func logging(to logger: Logger, identifier: CodeIdentifier = MagicConstantCodeIdentifier(file: #file, function: #function, line: #line), name: String, outputLogLevel: LogLevel = .info, failureLogLevel: LogLevel = .warning, subscribeLogLevel: LogLevel = .debug, outputMapper: @escaping (Output) -> String = { "\($0)" }) -> Publishers.HandleEvents<Self> {
		return handleEvents(
			receiveSubscription: { _ in logger.log(subscribeLogLevel, "\(name) initiated", identifier) },
			receiveOutput: { logger.log(outputLogLevel, "\(name): \(outputMapper($0))", identifier) },
			receiveCompletion: {
				if case let Subscribers.Completion.failure(error) = $0 {
					logger.log(failureLogLevel, "\(name): \(error)", identifier)
				}
			}
		)
	}
}
#endif
