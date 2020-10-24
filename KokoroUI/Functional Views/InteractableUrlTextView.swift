//
//  Created on 24/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class InteractableUrlTextView: UITextView {
	public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard
			let textPosition = closestPosition(to: point),
			let range = tokenizer.rangeEnclosingPosition(textPosition, with: .character, inDirection: .layout(.left))
		else { return false }
		let startIndex = offset(from: beginningOfDocument, to: range.start)
		return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
	}
}
#endif
