//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
public enum SystemUILocalizable {
	private static let uiKitBundle = Bundle(identifier: "com.apple.UIKit")!

	static var cancel: String {
		return uiKitBundle.localizedString(forKey: "Cancel", value: "", table: nil)
	}

	static var back: String {
		return uiKitBundle.localizedString(forKey: "Back", value: "", table: nil)
	}
}
#endif
