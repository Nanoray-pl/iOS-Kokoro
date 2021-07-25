//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct LoggedError: Error {
	public let wrappedError: Error

	public init(wrapping error: Error) {
		wrappedError = (error as? LoggedError)?.wrappedError ?? error
	}
}
