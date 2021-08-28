//
//  Created on 28/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class CodeIdentifierLoggerFactory: LoggerFactory {
	private let wrapped: LoggerFactory

	public init(wrapping wrapped: LoggerFactory) {
		self.wrapped = wrapped
	}

	public func createLogger(name: String, level: LogLevel) -> Logger {
		return CodeIdentifierLogger(wrapping: wrapped.createLogger(name: name, level: level))
	}

	private class CodeIdentifierLogger: Logger {
		private let wrapped: Logger

		var level: LogLevel

		init(wrapping wrapped: Logger) {
			self.wrapped = wrapped
			level = wrapped.level
		}

		private func identifier(file: String, function: String, line: Int) -> String {
			return "\(file.split(separator: "/").last!):\(function):\(line)"
		}

		func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, function: String, line: Int) {
			guard level >= self.level else { return }

			let builtMessage = message()
			let builtMessageWithPrefix = builtMessage.isEmpty ? "" : ": \(builtMessage)"
			let finalMessage = "\(identifier(file: file, function: function, line: line))\(builtMessageWithPrefix)"

			wrapped.log(level, finalMessage, file: file, function: function, line: line)
		}
	}
}
