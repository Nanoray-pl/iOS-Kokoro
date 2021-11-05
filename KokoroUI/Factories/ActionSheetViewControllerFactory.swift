//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public enum ActionSheetSource {
	case view(_ view: UIView)
	case barButtonItem(_ barButtonItem: UIBarButtonItem)
}

public struct ActionSheetAction {
	public typealias Style = UIAlertAction.Style

	public let title: String
	public let style: Style
	public let handler: (() -> Void)?

	public init(
		title: String,
		style: Style,
		handler: (() -> Void)? = nil
	) {
		self.title = title
		self.style = style
		self.handler = handler
	}
}

public protocol ActionSheetViewControllerFactory {
	func createActionSheet(source: ActionSheetSource, title: String?, message: String?, actions: [ActionSheetAction]) -> UIViewController
}

public class DefaultActionSheetViewControllerFactory: ActionSheetViewControllerFactory {
	public init() {}

	public func createActionSheet(source: ActionSheetSource, title: String?, message: String?, actions: [ActionSheetAction]) -> UIViewController {
		let controller = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		actions.forEach { action in
			controller.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
				// delaying, to make sure the action sheet is no longer present
				DispatchQueue.main.async {
					action.handler?()
				}
			})
		}
		switch source {
		case let .view(view):
			controller.popoverPresentationController?.sourceView = view
		case let .barButtonItem(barButtonItem):
			controller.popoverPresentationController?.barButtonItem = barButtonItem
		}
		return controller
	}
}
#endif
