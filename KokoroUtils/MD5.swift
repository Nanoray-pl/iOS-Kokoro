//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CryptoKit)
import CryptoKit

public struct MD5: CustomStringConvertible {
	public let digest: Data

	public var hex: String {
		return digest.map { String(format: "%02hhx", $0) }.joined()
	}

	public var description: String {
		return hex
	}

	public init(from data: Data) {
		digest = Data(Insecure.MD5.hash(data: data))
	}
}
#endif
