//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public struct NotPredicateBuilder<Upstream: PredicateBuilder>: PredicateBuilder {
	public typealias ResultType = Upstream.ResultType

	private let upstream: Upstream

	public init(upstream: Upstream) {
		self.upstream = upstream
	}

	public func build() -> NSPredicate {
		return NSCompoundPredicate(notPredicateWithSubpredicate: upstream.build())
	}
}

public prefix func ! <Upstream: PredicateBuilder>(upstream: Upstream) -> NotPredicateBuilder<Upstream> {
	return .init(upstream: upstream)
}
#endif
