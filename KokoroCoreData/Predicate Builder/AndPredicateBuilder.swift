//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public struct AndPredicateBuilder<LHS, RHS>: PredicateBuilder where LHS: PredicateBuilder, RHS: PredicateBuilder, LHS.ResultType == RHS.ResultType {
	public typealias ResultType = LHS.ResultType

	private let lhs: LHS
	private let rhs: RHS

	public init(lhs: LHS, rhs: RHS) {
		self.lhs = lhs
		self.rhs = rhs
	}

	public func build() -> NSPredicate {
		return NSCompoundPredicate(andPredicateWithSubpredicates: [lhs.build(), rhs.build()])
	}
}

public func && <LHS, RHS>(lhs: LHS, rhs: RHS) -> AndPredicateBuilder<LHS, RHS> where LHS: PredicateBuilder, RHS: PredicateBuilder, LHS.ResultType == RHS.ResultType {
	return .init(lhs: lhs, rhs: rhs)
}
#endif
