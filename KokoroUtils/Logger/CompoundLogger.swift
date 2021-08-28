//
//  Created on 28/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class CompoundLoggerFactory: LoggerFactory {
	private let wrapped: [LoggerFactory]

	public init(wrapping wrapped: [LoggerFactory]) {
		self.wrapped = wrapped
	}

	public func createLogger(name: String, level: LogLevel) -> Logger {
		return CompoundLogger(wrapping: wrapped.map { $0.createLogger(name: name, level: level) })
	}

	private class CompoundLogger: Logger {
		private let wrapped: [Logger]

		var level: LogLevel

		init(wrapping wrapped: [Logger]) {
			self.wrapped = wrapped
			level = wrapped.map(\.level).max() ?? .info
		}

		private func identifier(file: String, function: String, line: Int) -> String {
			return "\(file.split(separator: "/").last!):\(function):\(line)"
		}

		func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, function: String, line: Int) {
			guard level >= self.level else { return }
			wrapped.forEach { $0.log(level, message(), file: file, function: function, line: line) }
		}
	}
}
