//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import Foundation

public struct EquatablePredicateBuilder<ResultType: NSManagedObject & ManagedObject, ElementType: Equatable & CVarArgConvertible>: PredicateBuilder {
	fileprivate enum Operator: String {
		case equals = "==", notEquals = "!="
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

public func == <ResultType: NSManagedObject & ManagedObject, ElementType: Equatable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> EquatablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .equals, value: rhs)
}

public func == <ResultType: NSManagedObject & ManagedObject, ElementType: Equatable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> EquatablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .equals, value: rhs)
}

public func != <ResultType: NSManagedObject & ManagedObject, ElementType: Equatable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType>, rhs: ElementType) -> EquatablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .notEquals, value: rhs)
}

public func != <ResultType: NSManagedObject & ManagedObject, ElementType: Equatable & CVarArgConvertible>(lhs: KeyPath<ResultType, ElementType?>, rhs: ElementType) -> EquatablePredicateBuilder<ResultType, ElementType> {
	return .init(expression: NSExpression(forKeyPath: lhs), operator: .notEquals, value: rhs)
}
#endif
