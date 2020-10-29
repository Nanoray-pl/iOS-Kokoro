//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

private enum OptionalUnwrapError: Error {
	case error
}

public extension Optional {
	func unwrap() throws -> Wrapped {
		switch self {
		case let .some(value):
			return value
		case .none:
			throw OptionalUnwrapError.error
		}
	}
}
