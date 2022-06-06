//
//  Created on 28/01/2022.
//  Copyright © 2022 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public enum UrlSessionDataTaskProgress: Hashable {
	case sendProgress(_ progress: Progress)
	case receiveProgress(_ progress: Progress)
	case output(data: Data, response: URLResponse)

	public enum Progress: Hashable {
		case indeterminate(processedByteCount: Int = 0)
		case determinate(processedByteCount: Int, expectedByteCount: Int)
	}
}
#endif
