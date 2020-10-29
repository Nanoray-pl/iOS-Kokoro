//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

public struct ComparablePredicateBuilder<ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>: PredicateBuilder {
	fileprivate enum Operator: String {
		case greaterThan = ">", greaterThanOrEqualTo = ">=", lessThan = "<", lessThanOrEqualTo = "<="
	}

	private let expression: NSExpression
	private let `operator`: Operator
	private let value: ElementType

	fileprivate init(expression: NSExpression, operator: Operator, value: ElementType) {
		self.expression = expression
		self.operator = `operator`
		self.value = value
	}

	public func build() -> NSPredicate {
		return NSPredicate(format: "\(expression.keyPath) \(`operator`.rawValue) %@", value.asCVarArg())
	}
}

public func > <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .greaterThan, value: rhs)
}

public func > <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .greaterThan, value: rhs)
}

public func >= <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .greaterThanOrEqualTo, value: rhs)
}

public func >= <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .greaterThanOrEqualTo, value: rhs)
}

public func < <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .lessThan, value: rhs)
}

public func < <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .lessThan, value: rhs)
}

public func <= <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .lessThanOrEqualTo, value: rhs)
}

public func <= <ResultType: NSManagedObject & ManagedObject, ElementType: Comparable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> ComparablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .lessThanOrEqualTo, value: rhs)
}
#endif
