//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation) && canImport(UIKit)
import Foundation

public enum SystemUILocalizable {
	private static let uiKitBundle = Bundle(identifier: "com.apple.UIKit")!

	public static var cancel: String {
		return uiKitBundle.localizedString(forKey: "Cancel", value: "", table: nil)
	}

	public static var back: String {
		return uiKitBundle.localizedString(forKey: "Back", value: "", table: nil)
	}

	public static var done: String {
		return uiKitBundle.localizedString(forKey: "Done", value: "", table: nil)
	}

	public static var ok: String {
		return uiKitBundle.localizedString(forKey: "OK", value: "", table: nil)
	}

	public static var previous: String {
		return uiKitBundle.localizedString(forKey: "Previous", value: "", table: nil)
	}

	public static var next: String {
		return uiKitBundle.localizedString(forKey: "Next", value: "", table: nil)
	}
}
#endif
