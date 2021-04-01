//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

private func reusableIdentifier<T: Reusable>(type: T.Type, variant: String?) -> String {
	return [String(describing: type), variant].compactMap({ $0 }).joined(separator: "_")
}

public protocol Reusable: NSObjectProtocol {}

public extension UITableView {
	func register<T: UITableViewCell & Reusable>(cellType: T.Type, variant: String? = nil) {
		register(cellType, forCellReuseIdentifier: reusableIdentifier(type: cellType, variant: variant))
	}

	func dequeueReusableCell<T: UITableViewCell & Reusable>(ofType cellType: T.Type, variant: String? = nil, for indexPath: IndexPath) -> T {
		return dequeueReusableCell(withIdentifier: reusableIdentifier(type: cellType, variant: variant), for: indexPath) as! T
	}
}

public extension UICollectionView {
	func register<T: UICollectionViewCell & Reusable>(cellType: T.Type, variant: String? = nil) {
		register(cellType, forCellWithReuseIdentifier: reusableIdentifier(type: cellType, variant: variant))
	}

	func dequeueReusableCell<T: UICollectionViewCell & Reusable>(ofType cellType: T.Type, variant: String? = nil, for indexPath: IndexPath) -> T {
		return dequeueReusableCell(withReuseIdentifier: reusableIdentifier(type: cellType, variant: variant), for: indexPath) as! T
	}
}
#endif
