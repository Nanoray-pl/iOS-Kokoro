//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct AwaitTimeMagnitude: Hashable, Comparable {
	public static let none = AwaitTimeMagnitude(rawValue: 0)
	public static let computational = AwaitTimeMagnitude(rawValue: 1)
	public static let diskAccess = AwaitTimeMagnitude(rawValue: computational.rawValue * 10)
	public static let networkAccess = AwaitTimeMagnitude(rawValue: diskAccess.rawValue * 10)

	public var rawValue: Double

	public static func < (lhs: AwaitTimeMagnitude, rhs: AwaitTimeMagnitude) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}

	public static func + (lhs: AwaitTimeMagnitude, rhs: AwaitTimeMagnitude) -> AwaitTimeMagnitude {
		return .init(rawValue: lhs.rawValue + rhs.rawValue)
	}
}

extension Optional where Wrapped == AwaitTimeMagnitude {
	public static func + (lhs: AwaitTimeMagnitude?, rhs: AwaitTimeMagnitude?) -> AwaitTimeMagnitude? {
		if let lhs = lhs, let rhs = rhs {
			return lhs + rhs
		} else {
			return nil
		}
	}
}
