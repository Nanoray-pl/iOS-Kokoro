//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

class MenuViewController: UITableViewController {
	private struct Section {
		let header: String?
		let footer: String?
		let cells: [Cell]

		init(header: String? = nil, footer: String? = nil, cells: [Cell]) {
			self.header = header
			self.footer = footer
			self.cells = cells
		}
	}

	private enum Cell {
		case proportionalOffsetConstraint, aspectRatioEqualConstraint, minMaxLengthConstraint
		case flexColumnCollectionViewLayout, cardDeckView
		case progressBar
	}

	private unowned let router: Router

	private let sections: [Section] = [
		.init(header: "Non-basic Constraints", cells: [.proportionalOffsetConstraint, .aspectRatioEqualConstraint, .minMaxLengthConstraint]),
		.init(header: "Containers", cells: [.flexColumnCollectionViewLayout, .cardDeckView]),
		.init(header: "Aesthetic", cells: [.progressBar]),
	]

	init(router: Router) {
		self.router = router
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

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section].header
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return sections[section].footer
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].cells.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.accessoryType = .disclosureIndicator
		switch sections[indexPath.section].cells[indexPath.row] {
		case .proportionalOffsetConstraint:
			cell.textLabel?.text = "ProportionalOffsetConstraint"
		case .aspectRatioEqualConstraint:
			cell.textLabel?.text = "AspectRatioEqualConstraint"
		case .minMaxLengthConstraint:
			cell.textLabel?.text = "MinMaxLengthConstraint"
		case .flexColumnCollectionViewLayout:
			cell.textLabel?.text = "FlexColumnCollectionViewLayout"
		case .cardDeckView:
			cell.textLabel?.text = "CardDeckView"
		case .progressBar:
			cell.textLabel?.text = "ProgressBar"
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: Animated.motionBased.value)
		switch sections[indexPath.section].cells[indexPath.row] {
		case .proportionalOffsetConstraint:
			router[ProportionalOffsetConstraintRoute.self].showProportionalOffsetConstraint(animated: Animated.motionBased.value)
		case .aspectRatioEqualConstraint, .minMaxLengthConstraint:
			break
		case .flexColumnCollectionViewLayout:
			router[FlexColumnCollectionViewLayoutRoute.self].showFlexColumnCollectionViewLayout(animated: Animated.motionBased.value)
		case .cardDeckView:
			router[CardDeckViewRoute.self].showCardDeckView(animated: Animated.motionBased.value)
		case .progressBar:
			router[ProgressBarsRoute.self].showProgressBars(animated: Animated.motionBased.value)
		}
	}
}
