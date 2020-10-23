//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(NotificationCenter) && canImport(UIKit)
import NotificationCenter
import UIKit

public class KeyboardSpacerView: UIView {
	private var heightConstraint: NSLayoutConstraint!

	public init() {
		super.init(frame: .zero)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		heightConstraint = heightAnchor.constraint(equalToConstant: 0)
		heightConstraint.activate()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func keyboardWillShow(notification: Notification) {
		handleKeyboardNotification(notification)
	}

	@objc private func keyboardWillHide(notification: Notification) {
		handleKeyboardNotification(notification)
	}

	private func handleKeyboardNotification(_ notification: Notification) {
		guard
			let userInfo = notification.userInfo,
			let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
			let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int).flatMap({ UIView.AnimationCurve(rawValue: $0) }),
			let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
		else { return }
		let visibleEndFrame = endFrame.intersection(UIScreen.main.bounds)
		updateKeyboardHeight(to: visibleEndFrame.height, duration: duration, curve: curve)
	}

	private func updateKeyboardHeight(to height: CGFloat, duration: TimeInterval, curve: UIView.AnimationCurve) {
		Animated.run(duration: duration, curve: curve) {
			self.heightConstraint.constant = height
			self.layoutIfNeeded()
		}
	}
}
#endif
