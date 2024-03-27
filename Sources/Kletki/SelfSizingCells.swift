import UIKit

public extension CellConfigurator where Cell: UITableViewCell {
	static func autoHeightFunction(configure: @escaping (Cell, Item, IndexPath, UITableView) -> Void) -> (Item, IndexPath, UITableView) -> CGFloat {
		let cell = Cell(style: .default, reuseIdentifier: nil)
		return { item, indexPath, tableView in
			configure(cell, item, indexPath, tableView)

			cell.setNeedsUpdateConstraints()
			cell.updateConstraintsIfNeeded()

			cell.bounds = CGRect(origin: .zero, size: CGSize(
				width: tableView.bounds.size.width,
				height: cell.bounds.height
			))

			cell.setNeedsLayout()
			cell.layoutIfNeeded()

			let height = cell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

			return tableView.separatorStyle == .none ? height : height + 1
		}
	}

	static func autoHeight(
		configure: @escaping (Cell, Item, IndexPath, UITableView) -> Void,
		didSelect: @escaping (Cell, Item, IndexPath, UITableView) -> Void = { _, _, _, _ in }
	) -> CellConfigurator {
		CellConfigurator(
			size: autoHeightFunction(configure: configure),
			configure: configure,
			didSelect: didSelect
		)
	}
}
