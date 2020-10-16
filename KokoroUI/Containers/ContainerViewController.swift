//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

open class ContainerViewController: UIViewController {
	public private(set) var contentViewController: UIViewController?

	open override var childForStatusBarStyle: UIViewController? {
		return contentViewController ?? super.childForStatusBarStyle
	}

	public init() {
		super.init(nibName: nil, bundle: nil)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private static func snapshot(_ view: UIView) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
		view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
		let result = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return result!
	}

	public func setContentViewController(_ contentViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
		let oldViewController = self.contentViewController
		let newViewController = contentViewController
		if oldViewController == newViewController {
			return
		}

		let snapshot: UIImageView?
		if animated {
			snapshot = UIImageView(image: Self.snapshot(view))
		} else {
			snapshot = nil
		}

		addChild(newViewController)
		view.addSubview(newViewController.view)
		newViewController.view.edgesToSuperview().activate()
		newViewController.didMove(toParent: self)
		self.contentViewController = contentViewController
		setNeedsStatusBarAppearanceUpdate()

		if let oldViewController = oldViewController {
			oldViewController.willMove(toParent: nil)
			oldViewController.view.removeFromSuperview()
			oldViewController.removeFromParent()
		}

		// fix stuck navigation bar
		if contentViewController.navigationItem.largeTitleDisplayMode != .never {
			self.navigationItem.largeTitleDisplayMode = .never
			self.navigationItem.largeTitleDisplayMode = contentViewController.navigationItem.largeTitleDisplayMode
		}

		if let snapshot = snapshot {
			view.addSubview(snapshot)
			// snapshot is only created when `animated` is `true`, so we can just always animate here
			Animated.run(
				animations: {
					snapshot.alpha = 0
				}, completion: {
					snapshot.removeFromSuperview()
					completion?()
				}
			)
		} else {
			completion?()
		}
	}
}
#endif
