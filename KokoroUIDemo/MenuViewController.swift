//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

class MenuViewController: UITableViewController {
	private enum Cell {
		case progressBars
	}

	unowned var router: ProgressBarsRoute!
	private let cells: [Cell] = [.progressBars]

	init() {
		super.init(style: .grouped)
		navigationItem.title = "KokoroUI Demo"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cells.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		switch cells[indexPath.row] {
		case .progressBars:
			cell.textLabel?.text = "Progress Bars"
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: Animated.motionBased.value)
		switch cells[indexPath.row] {
		case .progressBars:
			router.showProgressBars(animated: Animated.motionBased.value)
		}
	}
}
