//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol Reusable: NSObjectProtocol {}

public extension UITableView {
	func register<T: UITableViewCell & Reusable>(cellType: T.Type) {
		register(cellType, forCellReuseIdentifier: String(describing: cellType))
	}

	func dequeueReusableCell<T: UITableViewCell & Reusable>(ofType cellType: T.Type, for indexPath: IndexPath) -> T {
		return dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as! T
	}
}

public extension UICollectionView {
	func register<T: UICollectionViewCell & Reusable>(cellType: T.Type) {
		register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
	}

	func dequeueReusableCell<T: UICollectionViewCell & Reusable>(ofType cellType: T.Type, for indexPath: IndexPath) -> T {
		return dequeueReusableCell(withReuseIdentifier: String(describing: cellType), for: indexPath) as! T
	}
}
#endif
