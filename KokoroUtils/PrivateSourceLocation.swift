//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CryptoKit) && canImport(Foundation)
import Foundation

public struct PrivateSourceLocation: CustomStringConvertible {
	private let prefix: String?
	private let file: StaticString
	private let function: StaticString
	private let line: Int
	private let column: Int
	private let suffix: String?

	private var unsafeDescription: String {
		return [prefix, String("\(file)".split(separator: "/").last!), "\(function)", "\(line)", "\(column)", suffix].compactMap({ $0 }).joined(separator: ":")
	}

	public var description: String {
		#if DEBUG
		return unsafeDescription
		#else
		return MD5(from: Data(unsafeDescription.utf8)).hex
		#endif
	}

	public init(prefix: String? = nil, file: StaticString = #file, function: StaticString = #function, line: Int = #line, column: Int = #column, suffix: String? = nil) {
		self.prefix = prefix
		self.file = file
		self.function = function
		self.line = line
		self.column = column
		self.suffix = suffix
	}
}
#endif
