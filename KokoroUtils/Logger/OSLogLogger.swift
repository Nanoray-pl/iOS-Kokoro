//
//  Created on 28/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(os)
import os.log

public class OSLogLoggerFactory: LoggerFactory {
	private let includesCodeIdentifier: Bool

	public init(includesCodeIdentifier: Bool = true) {
		self.includesCodeIdentifier = includesCodeIdentifier
	}

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
			let finalMessage = builtMessage.isEmpty ? "" : builtMessage

			os_log("%@[%@] %@", type: Self.osLogType(for: level), level.symbol ?? "", name, finalMessage)
		}

		private static func osLogType(for level: LogLevel) -> OSLogType {
			switch level {
			case .verbose:
				return .info
			case .debug:
				return .info
			case .info:
				return .info
			case .warning:
				return .error
			case .error:
				return .error
			}
		}
	}
}
#endif
