//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if XCODE
import class Foundation.Bundle

private class BundleFinder {}

extension Foundation.Bundle {
	/// Returns the resource bundle associated with the current Swift module.
	static var module: Bundle = {
		let bundleName = "KokoroCoreDataTests"

		let candidates = [
			// Bundle should be present here when the package is linked into a framework.
			Bundle(for: BundleFinder.self).resourceURL,

			// Bundle should be present here when the package is linked into an App.
			Bundle.main.resourceURL,

			// For command-line tools.
			Bundle.main.bundleURL,
		].compactMap { $0 }

		for candidate in candidates {
			if let bundle = Bundle(url: candidate.appendingPathComponent("\(bundleName).bundle")) {
				return bundle
			}
			if let bundle = Bundle(url: candidate) {
				return bundle
			}
		}
		fatalError("unable to find bundle named \(bundleName)")
	}()
}
#endif
