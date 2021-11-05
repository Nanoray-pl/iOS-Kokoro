//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public extension Bundle {
	var isProduction: Bool {
		#if targetEnvironment(simulator) || DEBUG
		return false
		#elseif DEBUG
		if let appStoreReceiptURL = appStoreReceiptURL {
			return appStoreReceiptURL.lastPathComponent != "sandboxReceipt"
		} else {
			return true
		}
		#endif
	}
}
#endif
