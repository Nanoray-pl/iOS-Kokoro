//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

protocol FlexColumnCollectionViewLayoutRoute: class {
	func showFlexColumnCollectionViewLayout(animated: Bool)
}

class FlexColumnCollectionViewLayoutViewController: UIViewController {
	private var orientationSegmentedControl: UISegmentedControl!
	private var fillDirectionSegmentedControl: UISegmentedControl!
	private var lastColumnAlignmentSegmentedControl: UISegmentedControl!
	private var itemDistributionSegmentedControl: UISegmentedControl!

	private var columnConstraintSegmentedControl: UISegmentedControl!
	private var columnConstraintLabel: UILabel!
	private var columnCountStepper: UIStepper!
	private var columnWidthSlider: UISlider!

	private var columnSpacingLabel: UILabel!
	private var columnSpacingSlider: UISlider!
	private var rowSpacingLabel: UILabel!
	private var rowSpacingSlider: UISlider!

	private var itemCountLabel: UILabel!
	private var itemCountStepper: UIStepper!

	private var collectionView: UICollectionView!
	private var layout: FlexColumnCollectionViewLayout!

	private var items: [(length: CGFloat, color: UIColor)]!

	init() {
		super.init(nibName: nil, bundle: nil)
		items = [newItem(), newItem(), newItem(), newItem()]
		navigationItem.title = "FlexColumnCollectionViewLayout"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func newItem() -> (length: CGFloat, color: UIColor) {
		let lengths: [CGFloat] = [40, 45, 50, 55, 60]
		let colors: [UIColor] = [.systemRed, .systemBlue, .systemPink, .systemTeal, .systemGreen, .systemOrange, .systemYellow, .systemPurple, .systemIndigo]
		return (length: lengths.randomElement()!, color: colors.randomElement()!)
	}

	override func loadView() {
		super.loadView()
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		view.backgroundColor = .systemBackground
		layout = FlexColumnCollectionViewLayout()

		let stack = UIStackView().with { [parent = view!] in
			$0.axis = .vertical
			$0.spacing = 12
			$0.isLayoutMarginsRelativeArrangement = true
			$0.layoutMargins = .init(insets: 20)

			orientationSegmentedControl = UISegmentedControl(items: ["Vertical", "Horizontal"]).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeOrientationSegmentedControlValue(_:)), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			fillDirectionSegmentedControl = UISegmentedControl(items: []).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeFillDirectionSegmentedControlValue(_:)), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Last Column Alignment"

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			lastColumnAlignmentSegmentedControl = UISegmentedControl(items: []).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeLastColumnAlignmentSegmentedControlValue(_:)), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Item Distribution"

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			itemDistributionSegmentedControl = UISegmentedControl(items: []).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeItemDistributionSegmentedControlValue(_:)), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			UIStackView().with { [parent = $0] in
				$0.axis = .horizontal
				$0.distribution = .fillEqually
				$0.spacing = 12

				UIStackView().with { [parent = $0] in
					$0.axis = .vertical
					$0.spacing = 4

					columnSpacingLabel = UILabel().with { [parent = $0] in
						$0.textColor = .label
						parent.addArrangedSubview($0)
					}

					columnSpacingSlider = UISlider().with { [parent = $0] in
						$0.minimumValue = 0
						$0.maximumValue = 40
						$0.value = Float(layout.columnSpacing)
						$0.addTarget(self, action: #selector(didChangeColumnSpacingSliderValue(_:)), for: .valueChanged)
						parent.addArrangedSubview($0)
					}

					parent.addArrangedSubview($0)
				}

				UIStackView().with { [parent = $0] in
					$0.axis = .vertical
					$0.spacing = 4

					rowSpacingLabel = UILabel().with { [parent = $0] in
						$0.textColor = .label
						parent.addArrangedSubview($0)
					}

					rowSpacingSlider = UISlider().with { [parent = $0] in
						$0.minimumValue = 0
						$0.maximumValue = 40
						$0.value = Float(layout.rowSpacing)
						$0.addTarget(self, action: #selector(didChangeRowSpacingSliderValue(_:)), for: .valueChanged)
						parent.addArrangedSubview($0)
					}

					parent.addArrangedSubview($0)
				}

				parent.addArrangedSubview($0)
			}

			columnConstraintSegmentedControl = UISegmentedControl(items: ["Column Count", "Min Column Width"]).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeColumnConstraintSegmentedControlValue(_:)), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			UIStackView().with { [parent = $0] in
				$0.axis = .horizontal
				$0.distribution = .fillEqually
				$0.spacing = 12

				columnConstraintLabel = UILabel().with { [parent = $0] in
					$0.textColor = .label

					parent.addArrangedSubview($0)
					parent.setCustomSpacing(4, after: $0)
				}

				columnCountStepper = UIStepper().with { [parent = $0] in
					$0.minimumValue = 1
					$0.maximumValue = 10
					$0.stepValue = 1
					$0.addTarget(self, action: #selector(didChangeColumnCountStepperValue(_:)), for: .valueChanged)
					parent.addArrangedSubview($0)
				}

				columnWidthSlider = UISlider().with { [parent = $0] in
					$0.minimumValue = 20
					$0.maximumValue = 300
					$0.addTarget(self, action: #selector(didChangeColumnWidthSliderValue(_:)), for: .valueChanged)
					parent.addArrangedSubview($0)
				}

				parent.addArrangedSubview($0)
			}

			UIStackView().with { [parent = $0] in
				$0.axis = .horizontal
				$0.distribution = .fillEqually
				$0.spacing = 12

				itemCountLabel = UILabel().with { [parent = $0] in
					$0.textColor = .label
					parent.addArrangedSubview($0)
				}

				itemCountStepper = UIStepper().with { [parent = $0] in
					$0.minimumValue = 0
					$0.maximumValue = 500
					$0.stepValue = 1
					$0.value = Double(items.count)
					$0.addTarget(self, action: #selector(didChangeItemCountStepperValue(_:)), for: .valueChanged)
					parent.addArrangedSubview($0)
				}

				parent.addArrangedSubview($0)
			}

			parent.addSubview($0)
			constraints += $0.horizontalEdges(to: parent.safeAreaLayoutGuide)
		}

		collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).with { [parent = view!] in
			$0.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
			$0.dataSource = self
			$0.delegate = self

			parent.addSubview($0)
			constraints += $0.horizontalEdges(to: parent.safeAreaLayoutGuide)
		}

		constraints += [
			stack.top(to: view.safeAreaLayoutGuide),
			collectionView.topToBottom(of: stack),
			collectionView.bottom(to: view),
		]

		updateFillDirectionSegmentedControl()
		updateLastColumnAlignmentSegmentedControl()
		updateItemDistributionSegmentedControl()
		updateColumnConstraintUI()
		updateColumnSpacingUI()
		updateRowSpacingUI()
		updateItemCountUI()

		DispatchQueue.main.async {
			self.orientationSegmentedControl.selectedSegmentIndex = 0
			self.fillDirectionSegmentedControl.selectedSegmentIndex = 0
			self.lastColumnAlignmentSegmentedControl.selectedSegmentIndex = 0
			self.itemDistributionSegmentedControl.selectedSegmentIndex = 0
			self.columnConstraintSegmentedControl.selectedSegmentIndex = 1
		}
	}

	@objc private func didChangeOrientationSegmentedControlValue(_ sender: UISegmentedControl) {
		if sender.selectedSegmentIndex == 0 {
			layout.orientation = .vertical()
		} else {
			layout.orientation = .horizontal()
		}
		updateFillDirectionSegmentedControl()
		updateLastColumnAlignmentSegmentedControl()
		updateItemDistributionSegmentedControl()

		DispatchQueue.main.async {
			self.fillDirectionSegmentedControl.selectedSegmentIndex = 0
			self.lastColumnAlignmentSegmentedControl.selectedSegmentIndex = 0
			self.itemDistributionSegmentedControl.selectedSegmentIndex = 0
		}
	}

	@objc private func didChangeFillDirectionSegmentedControlValue(_ sender: UISegmentedControl) {
		switch layout.orientation {
		case let .vertical(_, lastColumnAlignment, itemDistribution):
			let values: [FlexColumnCollectionViewLayout.Orientation.FillDirection.Vertical] = [.leftToRight, .rightToLeft]
			layout.orientation = .vertical(fillDirection: values[sender.selectedSegmentIndex], lastColumnAlignment: lastColumnAlignment, itemDistribution: itemDistribution)
		case let .horizontal(_, lastColumnAlignment, itemDistribution):
			let values: [FlexColumnCollectionViewLayout.Orientation.FillDirection.Horizontal] = [.topToBottom, .bottomToTop]
			layout.orientation = .horizontal(fillDirection: values[sender.selectedSegmentIndex], lastColumnAlignment: lastColumnAlignment, itemDistribution: itemDistribution)
		}
	}

	@objc private func didChangeLastColumnAlignmentSegmentedControlValue(_ sender: UISegmentedControl) {
		switch layout.orientation {
		case let .vertical(fillDirection, _, itemDistribution):
			let values: [FlexColumnCollectionViewLayout.Orientation.LastColumnAlignment.Vertical] = [.left, .center, .right, .fillEqually]
			layout.orientation = .vertical(fillDirection: fillDirection, lastColumnAlignment: values[sender.selectedSegmentIndex], itemDistribution: itemDistribution)
		case let .horizontal(fillDirection, _, itemDistribution):
			let values: [FlexColumnCollectionViewLayout.Orientation.LastColumnAlignment.Horizontal] = [.top, .center, .bottom, .fillEqually]
			layout.orientation = .horizontal(fillDirection: fillDirection, lastColumnAlignment: values[sender.selectedSegmentIndex], itemDistribution: itemDistribution)
		}
	}

	@objc private func didChangeItemDistributionSegmentedControlValue(_ sender: UISegmentedControl) {
		switch layout.orientation {
		case let .vertical(fillDirection, lastColumnAlignment, _):
			let values: [FlexColumnCollectionViewLayout.Orientation.ItemDistribution.Vertical] = [.top, .center, .bottom, .fill]
			layout.orientation = .vertical(fillDirection: fillDirection, lastColumnAlignment: lastColumnAlignment, itemDistribution: values[sender.selectedSegmentIndex])
		case let .horizontal(fillDirection, lastColumnAlignment, _):
			let values: [FlexColumnCollectionViewLayout.Orientation.ItemDistribution.Horizontal] = [.left, .center, .right, .fill]
			layout.orientation = .horizontal(fillDirection: fillDirection, lastColumnAlignment: lastColumnAlignment, itemDistribution: values[sender.selectedSegmentIndex])
		}
	}

	@objc private func didChangeColumnConstraintSegmentedControlValue(_ sender: UISegmentedControl) {
		if sender.selectedSegmentIndex == 0 {
			layout.columnConstraint = .count(2)
		} else {
			layout.columnConstraint = .minLength(150)
		}
		updateColumnConstraintUI()
	}

	@objc private func didChangeColumnSpacingSliderValue(_ sender: UIStepper) {
		layout.columnSpacing = CGFloat(columnSpacingSlider.value)
		updateColumnSpacingUI()
	}

	@objc private func didChangeRowSpacingSliderValue(_ sender: UIStepper) {
		layout.rowSpacing = CGFloat(rowSpacingSlider.value)
		updateRowSpacingUI()
	}

	@objc private func didChangeColumnCountStepperValue(_ sender: UIStepper) {
		updateColumnConstraint()
	}

	@objc private func didChangeColumnWidthSliderValue(_ sender: UIStepper) {
		updateColumnConstraint()
	}

	@objc private func didChangeItemCountStepperValue(_ sender: UIStepper) {
		let targetCount = Int(sender.value)
		while items.count > targetCount {
			items.removeLast()
		}
		while items.count < targetCount {
			items.append(newItem())
		}
		updateItemCountUI()
		collectionView.reloadData()
	}

	private func updateFillDirectionSegmentedControl() {
		fillDirectionSegmentedControl.removeAllSegments()
		switch layout.orientation {
		case .vertical:
			fillDirectionSegmentedControl.insertSegment(withTitle: "Left to Right", at: 0, animated: false)
			fillDirectionSegmentedControl.insertSegment(withTitle: "Right to Left", at: 1, animated: false)
		case .horizontal:
			fillDirectionSegmentedControl.insertSegment(withTitle: "Top to Bottom", at: 0, animated: false)
			fillDirectionSegmentedControl.insertSegment(withTitle: "Bottom to Top", at: 1, animated: false)
		}
	}

	private func updateLastColumnAlignmentSegmentedControl() {
		lastColumnAlignmentSegmentedControl.removeAllSegments()
		switch layout.orientation {
		case .vertical:
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Left", at: 0, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Center", at: 1, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Right", at: 2, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Fill Equally", at: 3, animated: false)
		case .horizontal:
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Top", at: 0, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Center", at: 1, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Bottom", at: 2, animated: false)
			lastColumnAlignmentSegmentedControl.insertSegment(withTitle: "Fill Equally", at: 3, animated: false)
		}
	}

	private func updateItemDistributionSegmentedControl() {
		itemDistributionSegmentedControl.removeAllSegments()
		switch layout.orientation {
		case .vertical:
			itemDistributionSegmentedControl.insertSegment(withTitle: "Top", at: 0, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Center", at: 1, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Bottom", at: 2, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Fill", at: 3, animated: false)
		case .horizontal:
			itemDistributionSegmentedControl.insertSegment(withTitle: "Left", at: 0, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Center", at: 1, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Right", at: 2, animated: false)
			itemDistributionSegmentedControl.insertSegment(withTitle: "Fill", at: 3, animated: false)
		}
	}

	private func updateColumnSpacingUI() {
		columnSpacingLabel.text = "Column Spacing \(Int(layout.columnSpacing))"
		columnSpacingSlider.value = Float(layout.columnSpacing)
	}

	private func updateRowSpacingUI() {
		rowSpacingLabel.text = "Row Spacing \(Int(layout.rowSpacing))"
		rowSpacingSlider.value = Float(layout.rowSpacing)
	}

	private func updateColumnConstraint() {
		switch layout.columnConstraint {
		case .count:
			layout.columnConstraint = .count(Int(columnCountStepper.value))
		case .minLength:
			layout.columnConstraint = .minLength(CGFloat(columnWidthSlider.value))
		}
		updateColumnConstraintUI()
	}

	private func updateColumnConstraintUI() {
		switch layout.columnConstraint {
		case let .count(count):
			columnConstraintLabel.text = "Columns: \(count)"
			columnCountStepper.isHidden = false
			columnWidthSlider.isHidden = true
			columnCountStepper.value = Double(count)
		case let .minLength(minLength):
			columnConstraintLabel.text = "Column Width: ≥\(Int(minLength))"
			columnCountStepper.isHidden = true
			columnWidthSlider.isHidden = false
			columnWidthSlider.value = Float(minLength)
		}
	}

	private func updateItemCountUI() {
		itemCountLabel.text = "Items: \(items.count)"
	}
}

extension FlexColumnCollectionViewLayoutViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath).with {
			$0.contentView.backgroundColor = items[indexPath.item].color
		}
	}
}

extension FlexColumnCollectionViewLayoutViewController: FlexColumnCollectionViewLayoutDelegate {
	func itemRowLength(at indexPath: IndexPath, inColumn columnIndex: Int, inRow rowIndex: Int, rowAttributes: FlexColumnCollectionViewLayout.RowAttributes, in layout: FlexColumnCollectionViewLayout, in collectionView: UICollectionView) -> FlexColumnCollectionViewLayout.ItemRowLength {
		return .fixed(items[indexPath.item].length)
	}
}
