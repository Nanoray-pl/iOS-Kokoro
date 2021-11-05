//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ViewControllerPresenter: Router {
	private struct WeakModalWrapper {
		private(set) weak var controller: UIViewController?

		init(controller: UIViewController) {
			self.controller = controller
		}
	}

	public unowned let parentRouter: Router?

	public var childRouters: [Router] {
		return modals.compactMap { $0.controller as? Router }
	}

	private unowned let controller: UIViewController

	private var isExecutingModalAction = false
	private var queuedModalActions = [() -> Void]()

	private var modals = [WeakModalWrapper]() {
		didSet {
			guard modals.contains(where: { $0.controller == nil }) else { return }
			modals = modals.filter { $0.controller != nil }
		}
	}

	public init(wrapping controller: UIViewController, parentRouter: Router? = nil) {
		self.controller = controller
		self.parentRouter = parentRouter
	}

	private func enqueueModalAction(_ action: @escaping () -> Void) {
		queuedModalActions.append(action)
		executeNextModalAction()
	}

	private func executeNextModalAction() {
		if isExecutingModalAction { return }
		guard let modalAction = queuedModalActions.first else { return }
		isExecutingModalAction = true
		queuedModalActions.removeFirst()
		modalAction()
	}

	public func present(_ presentedController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
		enqueueModalAction { [unowned self, controller = modals.compactMap(\.controller).last ?? controller] in
			self.modals.append(.init(controller: presentedController))
			controller.present(presentedController, animated: animated) { [weak self] in
				self?.isExecutingModalAction = false
				self?.executeNextModalAction()
				completion?()
			}
		}
	}

	public func dismiss(_ controller: UIViewController?, animated: Bool, completion: (() -> Void)? = nil) {
		guard let controller = controller, modals.contains(where: { $0.controller == controller }) else {
			completion?()
			return
		}

		enqueueModalAction { [unowned self] in
			self.modals.removeFirst { $0.controller == controller }
			controller.dismiss(animated: animated) { [weak self] in
				self?.isExecutingModalAction = false
				self?.executeNextModalAction()
				completion?()
			}
		}
	}

	public func dismissAll(atOnce: Bool = true, animated: Bool, completion: (() -> Void)? = nil) {
		if atOnce {
			modals.compactMap(\.controller).enumerated().reversed().forEach { index, controller in
				controller.dismiss(animated: animated, completion: index == 0 ? completion : nil)
			}
		} else {
			modals.compactMap(\.controller).enumerated().reversed().forEach { index, controller in
				dismiss(controller, animated: animated, completion: index == 0 ? completion : nil)
			}
		}
	}
}
#endif
