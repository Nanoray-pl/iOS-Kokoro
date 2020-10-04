//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public struct Identifiable<Identifier: Hashable, Element>: Hashable {
	public let identifier: Identifier
	public let element: Element

	public static func == (lhs: Identifiable<Identifier, Element>, rhs: Identifiable<Identifier, Element>) -> Bool {
		return lhs.identifier == rhs.identifier
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}

	public init(identifier: Identifier, element: Element) {
		self.identifier = identifier
		self.element = element
	}
}

#if canImport(Foundation)
import Foundation

public extension Identifiable where Identifier == UUID {
	init(_ element: Element) {
		identifier = UUID()
		self.element = element
	}
}
#endif
