//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class PinnedOnTopView: UIView {
	private let application: UIApplication
	private let notificationCenter: NotificationCenter
	private let maxWindowLevel: UIWindow.Level
	private var isTransitioningToNewWindow = false
	private weak var oldWindow: UIWindow?

	private lazy var privateObserver = Observer(parent: self)

	public init(application: UIApplication = .shared, notificationCenter: NotificationCenter = .default, maxWindowLevel: UIWindow.Level) {
		self.application = application
		self.notificationCenter = notificationCenter
		self.maxWindowLevel = maxWindowLevel
		super.init(frame: .zero)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stopWindowObserving()
	}

	public override func didMoveToWindow() {
		super.didMoveToWindow()
		oldWindow?.removeSubviewObserver(privateObserver)
		oldWindow = window
		window?.addSubviewObserver(privateObserver)
		if isTransitioningToNewWindow { return }

		if window == nil {
			stopWindowObserving()
		} else {
			setupConstraints()
			startWindowObserving()
		}
	}

	private func startWindowObserving() {
		notificationCenter.addObserver(self, selector: #selector(windowDidBecomeVisible), name: UIWindow.didBecomeVisibleNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(windowDidBecomeHidden), name: UIWindow.didBecomeHiddenNotification, object: nil)
	}

	private func stopWindowObserving() {
		notificationCenter.removeObserver(self, name: UIWindow.didBecomeVisibleNotification, object: nil)
		notificationCenter.removeObserver(self, name: UIWindow.didBecomeHiddenNotification, object: nil)
	}

	@objc private func windowDidBecomeVisible() {
		updateContainingWindow()
	}

	@objc private func windowDidBecomeHidden() {
		updateContainingWindow()
	}

	private func updateContainingWindow() {
		if window == nil { return }
		let topMostWindow = application.windows.last { !$0.isHidden && $0.windowLevel <= maxWindowLevel && "\(type(of: $0))" != "UITextEffectsWindow" } ?? application.windows.first!
		if window == topMostWindow { return }

		isTransitioningToNewWindow = true
		removeFromSuperview()
		topMostWindow.addSubview(self)
		setupConstraints()
		isTransitioningToNewWindow = false
	}

	private func setupConstraints() {
		edgesToSuperview().activate()
	}

	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if let result = super.hitTest(point, with: event), result.isContained(in: self) {
			return result
		} else {
			return nil
		}
	}

	private class Observer: NSObject, UIViewSubviewObserver {
		private unowned let parent: PinnedOnTopView

		init(parent: PinnedOnTopView) {
			self.parent = parent
		}

		func didAddSubview(_ subview: UIView, to view: UIView) {
			parent.superview?.bringSubviewToFront(parent)
		}

		func didRemoveSubview(_ subview: UIView, from view: UIView) {}
	}
}
#endif
