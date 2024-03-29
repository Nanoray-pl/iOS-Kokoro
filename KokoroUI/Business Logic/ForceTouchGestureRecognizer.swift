/// GTForceTouchGestureRecognizer
///
/// Copyright (c) 2018 Giuseppe Travasoni. Licensed under the MIT license, as follows:
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

#if canImport(UIKit)
import UIKit.UIGestureRecognizerSubclass

/// Force touch gesture recognizer
public class ForceTouchGestureRecognizer: UIGestureRecognizer {
	var deepPressedAt: TimeInterval = 0
	weak var gestureTarget: AnyObject?
	var gestureAction: Selector
	var hardTriggerMinTime: TimeInterval
	let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
	let threshold: CGFloat

	var deepPressed: Bool = false {
		didSet {
			guard deepPressed, !oldValue else { return }
			deepPressedAt = NSDate.timeIntervalSinceReferenceDate
		}
	}

	/// The current state of the gesture recognizer
	public override var state: UIGestureRecognizer.State {
		didSet {
			guard oldValue != state else { return }
			switch state {
			case .began:
				feedbackGenerator.prepare()
			case .ended:
				feedbackGenerator.impactOccurred()
				_ = gestureTarget?.perform(gestureAction, with: self)
			default:
				return
			}
		}
	}

	/// Initialize a force touch gesture recognizer.
	/// - Parameter target: target object on which call the selector
	/// - Parameter action: selector to perform on target object
	/// - Parameter threshold: minimum percentage force value to validate touch (default 0.75)
	/// - Parameter hardTriggerMinTime: minumum time over threshold percentage to validate touch (default 0.5)
	public required init(target: AnyObject?, action: Selector, threshold: CGFloat = 0.75, hardTriggerMinTime: TimeInterval = 0.5) {
		gestureTarget = target
		gestureAction = action
		self.threshold = threshold
		self.hardTriggerMinTime = hardTriggerMinTime
		super.init(target: nil, action: nil)
	}

	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		handleTouch(touches.first)
	}

	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		handleTouch(touches.first)
	}

	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		state = deepPressed ? UIGestureRecognizer.State.ended : UIGestureRecognizer.State.failed
		deepPressed = false
		super.touchesEnded(touches, with: event)
	}

	func handleTouch(_ touch: UITouch?) {
		guard view != nil, let touch = touch, touch.force != 0 && touch.maximumPossibleForce != 0 else { return }
		let forcePercentage = touch.force / touch.maximumPossibleForce
		if deepPressed && forcePercentage <= 0 {
			state = UIGestureRecognizer.State.ended
			return
		}
		handleForceTouch(with: forcePercentage)
	}

	private func handleForceTouch(with forcePercentage: CGFloat) {
		let currentTime = NSDate.timeIntervalSinceReferenceDate
		if !deepPressed && forcePercentage >= threshold {
			deepPressed = true
			state = UIGestureRecognizer.State.began
			return
		}
		if deepPressed && currentTime - deepPressedAt > hardTriggerMinTime && forcePercentage == 1.0 {
			state = UIGestureRecognizer.State.ended
		}
	}
}
#endif
