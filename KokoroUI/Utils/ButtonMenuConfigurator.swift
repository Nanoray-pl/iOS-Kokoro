//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ButtonMenuConfigurator {
	public final class ButtonTargetHandler {
		private(set) weak var target: AnyObject?
		private(set) var selector: Selector

		public init(target: AnyObject, selector: Selector) {
			self.target = target
			self.selector = selector
		}
	}

	public enum ButtonHandler {
		case target(_ handler: ButtonTargetHandler)
		case closure(_ closure: () -> Void)
	}

	public class MenuItem {
		public let image: UIImage?
		public let title: String
		public let isDestructive: Bool

		fileprivate init(image: UIImage? = nil, title: String, isDestructive: Bool = false) {
			self.image = image
			self.title = title
			self.isDestructive = isDestructive
		}
	}

	public final class Menu: MenuItem {
		public let children: [MenuItem]

		public init(image: UIImage? = nil, title: String = "", isDestructive: Bool = false, children: [MenuItem]) {
			self.children = children
			super.init(image: image, title: title, isDestructive: isDestructive)
		}
	}

	public final class MenuAction: MenuItem {
		public let isDisabled: Bool
		public let handler: ButtonHandler?

		public init(image: UIImage? = nil, title: String, isDestructive: Bool = false, isDisabled: Bool = false, handler: ButtonHandler?) {
			self.isDisabled = isDisabled
			self.handler = handler
			super.init(image: image, title: title, isDestructive: isDestructive)
		}
	}

	public struct ActionSheetAction {
		public typealias Style = UIAlertAction.Style

		public let title: String
		public let style: Style
		public let handler: (() -> Void)?

		public init(title: String, style: Style, handler: (() -> Void)? = nil) {
			self.title = title
			self.style = style
			self.handler = handler
		}
	}

	public struct Actions {
		public enum Action {
			case handler(_ handler: ButtonHandler)
			case menu(_ menu: Menu)
		}

		let primaryAction: Action?
		let secondaryAction: Action?

		var nonMenuPrimaryAction: ButtonHandler? {
			if case let .handler(handler) = primaryAction {
				return handler
			} else {
				return nil
			}
		}

		var nonMenuSecondaryAction: ButtonHandler? {
			if case let .handler(handler) = secondaryAction {
				return handler
			} else {
				return nil
			}
		}

		var menu: Menu? {
			if case let .menu(menu) = primaryAction {
				return menu
			} else if case let .menu(menu) = secondaryAction {
				return menu
			} else {
				return nil
			}
		}

		private init(primaryAction: Action?, secondaryAction: Action?) {
			self.primaryAction = primaryAction
			self.secondaryAction = secondaryAction
		}

		init(handler: ButtonHandler) {
			self.init(primaryAction: .handler(handler), secondaryAction: nil)
		}

		init(primaryHandler: ButtonHandler, secondaryHandler: ButtonHandler) {
			self.init(primaryAction: .handler(primaryHandler), secondaryAction: .handler(secondaryHandler))
		}

		init(menu: Menu) {
			self.init(primaryAction: .menu(menu), secondaryAction: nil)
		}

		init(primaryMenu: Menu, secondaryHandler: ButtonHandler) {
			self.init(primaryAction: .menu(primaryMenu), secondaryAction: .handler(secondaryHandler))
		}

		init(primaryHandler: ButtonHandler, secondaryMenu: Menu) {
			self.init(primaryAction: .handler(primaryHandler), secondaryAction: .menu(secondaryMenu))
		}
	}

	private class Configuration {
		let actions: Actions
		weak var longPressGesture: UILongPressGestureRecognizer?
		weak var forceTouchGesture: ForceTouchGestureRecognizer?

		init(actions: Actions) {
			self.actions = actions
		}
	}

	private let alwaysUseActionSheet: Bool
	private let actionSheetPresenter: (_ source: UIView, _ title: String?, _ actions: [ActionSheetAction], _ animated: Bool) -> Void
	private var configurations = NSMapTable<UIButton, Configuration>(keyOptions: .weakMemory, valueOptions: .strongMemory)
	private lazy var uiKitBundle = Bundle(identifier: "com.apple.UIKit")!

	private var shouldUseActionSheet: Bool {
		if #available(iOS 14, *) {
			return alwaysUseActionSheet
		} else {
			return true
		}
	}

	init(actionSheetPresenter: @escaping (_ source: UIView, _ title: String?, _ actions: [ActionSheetAction], _ animated: Bool) -> Void, alwaysUseActionSheet: Bool = false) {
		self.actionSheetPresenter = actionSheetPresenter
		self.alwaysUseActionSheet = alwaysUseActionSheet
	}

	private func cleanUpConfiguration(of button: UIButton) {
		guard let configuration = configurations.object(forKey: button) else { return }

		if #available(iOS 14, *) {
			button.menu = nil
			button.showsMenuAsPrimaryAction = false
		}

		button.removeTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
		if let longPressGesture = configuration.longPressGesture {
			button.removeGestureRecognizer(longPressGesture)
		}
		if let forceTouchGesture = configuration.forceTouchGesture {
			button.removeGestureRecognizer(forceTouchGesture)
		}

		configurations.removeObject(forKey: button)
	}

	func configure(_ button: UIButton, actions: Actions?) {
		cleanUpConfiguration(of: button)
		guard let actions = actions else { return }

		let configuration = Configuration(actions: actions)

		if #available(iOS 14, *), !shouldUseActionSheet {
			button.menu = actions.menu.flatMap { uiMenu(from: $0, for: button) }
			button.showsMenuAsPrimaryAction = (actions.menu != nil && actions.nonMenuPrimaryAction == nil)

			if actions.nonMenuPrimaryAction != nil {
				button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
			}
		} else {
			button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
		}

		if actions.nonMenuSecondaryAction != nil {
			ForceTouchGestureRecognizer(target: self, action: #selector(didForceTouch(_:))).with {
				button.addGestureRecognizer($0)
				configuration.forceTouchGesture = $0
			}
			UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:))).with {
				button.addGestureRecognizer($0)
				configuration.longPressGesture = $0
			}
		}

		configurations.setObject(configuration, forKey: button)
	}

	@objc private func didTapButton(_ button: UIButton) {
		guard let configuration = configurations.object(forKey: button) else { return }
		switch configuration.actions.primaryAction {
		case let .handler(handler):
			let closure = self.closure(for: handler, for: button)
			closure()
		case let .menu(menu):
			if shouldUseActionSheet {
				showActionSheetBasedMenu(menu, from: button)
			}
		case .none:
			break
		}
	}

	@objc private func didForceTouch(_ recognizer: ForceTouchGestureRecognizer) {
		guard let button = recognizer.view as? UIButton else { return }
		handleSecondaryAction(of: button)
	}

	@objc private func didLongPress(_ recognizer: UILongPressGestureRecognizer) {
		guard let button = recognizer.view as? UIButton else { return }
		handleSecondaryAction(of: button)
	}

	private func handleSecondaryAction(of button: UIButton) {
		guard let configuration = configurations.object(forKey: button) else { return }
		switch configuration.actions.secondaryAction {
		case let .handler(handler):
			let closure = self.closure(for: handler, for: button)
			closure()
		case let .menu(menu):
			if shouldUseActionSheet {
				showActionSheetBasedMenu(menu, from: button)
			}
		case .none:
			break
		}
	}

	private func showActionSheetBasedMenu(_ menu: Menu, from button: UIButton) {
		var actions = menu.children.map { item -> ActionSheetAction in
			let closure: (() -> Void)?
			if let actionItem = item as? MenuAction {
				closure = actionItem.handler.flatMap { self.closure(for: $0, for: button) }
			} else if let menuItem = item as? Menu {
				closure = { [weak self, weak button] in
					guard let self = self, let button = button else { return }
					self.showActionSheetBasedMenu(menuItem, from: button)
				}
			} else {
				fatalError("Cannot handle menu item \(item)")
			}
			return ActionSheetAction(
				title: item.title,
				style: item.isDestructive ? .destructive : .default,
				handler: closure
			)
		}

		actions.append(.init(title: uiKitBundle.localizedString(forKey: "Cancel", value: "", table: nil), style: .cancel))
		actionSheetPresenter(button, menu.title.isEmpty ? nil : menu.title, actions, Animated.motionBased.value)
	}

	private func uiMenu(from menu: Menu, for button: UIButton) -> UIMenu {
		var options = UIMenu.Options()
		if menu.isDestructive {
			options.insert(.destructive)
		}

		return UIMenu(
			title: menu.title,
			image: menu.image,
			identifier: nil,
			options: menu.isDestructive ? .destructive : [],
			children: menu.children.map { uiMenuElement(from: $0, for: button) }
		)
	}

	private func uiAction(from action: MenuAction, for button: UIButton) -> UIAction {
		var attributes = UIMenuElement.Attributes()
		if action.isDestructive {
			attributes.insert(.destructive)
		}
		if action.isDisabled {
			attributes.insert(.disabled)
		}

		return UIAction(
			title: action.title,
			image: action.image,
			identifier: nil,
			discoverabilityTitle: nil,
			attributes: attributes,
			state: .off,
			handler: action.handler.flatMap { uiActionHandler(for: $0, for: button) } ?? { _ in }
		)
	}

	private func uiMenuElement(from item: MenuItem, for button: UIButton) -> UIMenuElement {
		if let item = item as? Menu {
			return uiMenu(from: item, for: button)
		} else if let item = item as? MenuAction {
			return uiAction(from: item, for: button)
		} else {
			fatalError("Cannot handle MenuItem \(item)")
		}
	}

	private func closure(for handler: ButtonHandler, for button: UIButton) -> (() -> Void) {
		return { [weak button] in
			switch handler {
			case let .target(handler):
				guard let target = handler.target else { return }
				let selectorArgumentCount = handler.selector.description.count(where: { $0 == ":" })
				switch selectorArgumentCount {
				case 0:
					_ = target.perform(handler.selector)
				case 1:
					_ = target.perform(handler.selector, with: button)
				default:
					fatalError("Cannot handle selector \(handler.selector)")
				}
			case let .closure(closure):
				closure()
			}
		}
	}

	private func uiActionHandler(for handler: ButtonHandler, for button: UIButton) -> ((UIAction) -> Void) {
		let closure = self.closure(for: handler, for: button)
		return { _ in closure() }
	}
}

extension ButtonMenuConfigurator {
	func configure(_ button: Button, actions: Actions?) {
		configure(button.wrappedButton, actions: actions)
	}
}
#endif
