//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public protocol Router: AnyObject {
	var parentRouter: Router? { get }
	var childRouters: [Router] { get }

	func optionalRouter<RouteType>(for routeType: RouteType.Type) -> RouteType?
	func router<RouteType>(for routeType: RouteType.Type) -> RouteType
}

public extension Router {
	var childRouters: [Router] {
		return []
	}

	var rootRouter: Router {
		var current: Router = self
		while true {
			if let next = current.parentRouter {
				current = next
			} else {
				break
			}
		}
		return current
	}

	private func firstUpstreamRouter<RouteType>(for routeType: RouteType.Type) -> RouteType? {
		return (self as? RouteType) ?? parentRouter?.firstUpstreamRouter(for: routeType)
	}

	private func lastDownstreamRouter<RouteType>(for routeType: RouteType.Type) -> RouteType? {
		for childRouter in childRouters.reversed() {
			if let childRouter = childRouter.lastDownstreamRouter(for: routeType) {
				return childRouter
			}
		}
		if let self = self as? RouteType {
			return self
		}
		return nil
	}

	func optionalRouter<RouteType>(for routeType: RouteType.Type) -> RouteType? {
		return lastDownstreamRouter(for: routeType) ?? firstUpstreamRouter(for: routeType)
	}

	func router<RouteType>(for routeType: RouteType.Type) -> RouteType {
		guard let router = optionalRouter(for: routeType) else {
			// we treat this as a programming error, hence the fatalError
			fatalError("No known router handling \(routeType).")
		}
		return router
	}

	subscript<RouteType>(_ routeType: RouteType.Type) -> RouteType {
		return router(for: routeType)
	}
}
