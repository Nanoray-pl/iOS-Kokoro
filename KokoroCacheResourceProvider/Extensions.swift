//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation) && canImport(CryptoKit) && canImport(ObjectiveC)
import KokoroCache
import KokoroResourceProvider

extension AnyResourceProvider: OnDiskCacheable {
	public var cacheIdentifier: String {
		return identifier
	}
}
#endif
