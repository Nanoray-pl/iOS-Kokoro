//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol CodeIdentifier {
	var stringRepresentation: String { get }
}

extension String: CodeIdentifier {
	public var stringRepresentation: String {
		return self
	}
}

public struct MagicConstantCodeIdentifier: CodeIdentifier {
	public let file: String
	public let function: String
	public let line: Int

	public var stringRepresentation: String {
		return "\(file.split(separator: "/").last!):\(function):\(line)"
	}

	public init(file: String, function: String, line: Int) {
		self.file = file
		self.function = function
		self.line = line
	}
}
