//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public enum ErrorMatchingStrategy {
	case byPresenceOnly
	case byDescription
	case custom(_ function: (Error, Error) -> Bool)

	public func areMatchingErrors(_ error1: Error?, _ error2: Error?) -> Bool {
		switch (error1, error2) {
		case (.none, .none):
			return true
		case (.none, .some), (.some, .none):
			return false
		case let (.some(error1), .some(error2)):
			switch self {
			case .byPresenceOnly:
				return true
			case .byDescription:
				return "\(error1)" == "\(error2)"
			case let .custom(function):
				return function(error1, error2)
			}
		}
	}
}
