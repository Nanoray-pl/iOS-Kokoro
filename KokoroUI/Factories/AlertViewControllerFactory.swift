//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public enum AlertTexts {
	case texts(title: String, message: String)
	case title(_ title: String)
	case message(_ message: String)
}

public struct AlertAction {
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

public extension AlertTexts {
	var title: String? {
		switch self {
		case let .texts(title, _):
			return title
		case let .title(title):
			return title
		default:
			return nil
		}
	}

	var message: String? {
		switch self {
		case let .texts(_, message):
			return message
		case let .message(message):
			return message
		default:
			return nil
		}
	}
}

public protocol AlertViewControllerFactory {
	func createAlert(texts: AlertTexts, actions: [AlertAction], accessibilityIdentifier: String?) -> UIViewController
}

public class DefaultAlertViewControllerFactory: AlertViewControllerFactory {
	public init() {}

	public func createAlert(texts: AlertTexts, actions: [AlertAction], accessibilityIdentifier: String?) -> UIViewController {
		let controller = UIAlertController(title: texts.title, message: texts.message, preferredStyle: .alert)
		controller.view.accessibilityIdentifier = accessibilityIdentifier
		actions.forEach { action in
			controller.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
				// delaying, to make sure the alert is no longer present
				DispatchQueue.main.async {
					action.handler?()
				}
			})
		}
		return controller
	}
}
#endif
