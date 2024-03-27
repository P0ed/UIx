import UIKit

/// A single displayable cell.
public protocol CellProtocol: UIView where Dimension == RootCell.Dimension, Container == RootCell.Container {
	/// Container type: UITableView or UICollectionView
	associatedtype Container: UIView
	/// Dimension to measure in configurator. CGFloat (height) for UITableViewCell or CGSize for UICollectionViewCell
	associatedtype Dimension
	/// Root cell type to be casted into for type erasure. UITableViewCell or UICollectionViewCell
	associatedtype RootCell: CellProtocol
}

/// Required information to register and retrieve displayable cells from containers
public struct CellInfo: Hashable {

	public let reuseID: String

	/// Type of displayable cell
	public let type: AnyClass

	public init(reuseID: String, type: AnyClass) {
		self.reuseID = reuseID
		self.type = type
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(reuseID)
		hasher.combine(ObjectIdentifier(type))
	}

	public static func == (lhs: CellInfo, rhs: CellInfo) -> Bool {
		lhs.reuseID == rhs.reuseID && lhs.type == rhs.type
	}
}

/// Configurator for a known cell and item type
public struct CellConfigurator<Cell: CellProtocol, Item> {
	public var cellInfo: CellInfo
	public var size: (Item, IndexPath, Cell.Container) -> Cell.Dimension
	public var configure: (Cell, Item, IndexPath, Cell.Container) -> Void
	public var didSelect: (Cell, Item, IndexPath, Cell.Container) -> Void

	public init(
		cellInfo: CellInfo = CellInfo(reuseID: "\(Cell.self)-\(Item.self)", type: Cell.self),
		size: @escaping (Item, IndexPath, Cell.Container) -> Cell.Dimension,
		configure: @escaping (Cell, Item, IndexPath, Cell.Container) -> Void,
		didSelect: @escaping (Cell, Item, IndexPath, Cell.Container) -> Void = { _, _, _, _ in }
	) {
		self.cellInfo = cellInfo
		self.size = size
		self.configure = configure
		self.didSelect = didSelect
	}
}

/// Unified version for CellConfigurator where item is unknown by the time of configure
/// Typically used to combine multiple CellConfigurators where items can be retrieved by their indexPaths
public struct RootCellConfigurator<Cell: CellProtocol> {
	/// Cells meta info for registration in container
	public var cellsInfo: Set<CellInfo>
	/// Reuse id generator
	public var reuseID: (IndexPath) -> String
	/// Size of cell
	public var size: (IndexPath, Cell.Container) -> Cell.Dimension
	/// Called at `willDisplayCell` delegate methods
	public var configure: (Cell, IndexPath, Cell.Container) -> Void
	/// Called at `didEndDisplayingCell` delegate methods
	public var teardown: (Cell, IndexPath, Cell.Container) -> Void = { _, _, _ in }
	/// Called at `didSelectCell` delegate methods
	public var didSelect: (Cell, IndexPath, Cell.Container) -> Void
}

public protocol TableCellConfiguratorType {
	var itemType: Any.Type { get }

	func asAny() -> CellConfigurator<UITableViewCell, Any>
}

public protocol CollectionCellConfiguratorType {
	var itemType: Any.Type { get }

	func asAny() -> CellConfigurator<UICollectionViewCell, Any>
}

public extension CellConfigurator {

	func transformingItem<Transformee>(_ transform: @escaping (Transformee) -> Item) -> CellConfigurator<Cell, Transformee> {
		CellConfigurator<Cell, Transformee>(
			cellInfo: cellInfo,
			size: { [size] in size(transform($0), $1, $2) },
			configure: { [configure] in configure($0, transform($1), $2, $3) },
			didSelect: { [didSelect] in didSelect($0, transform($1), $2, $3) }
		)
	}

	func transformingItemAt<Transformee>(_ transform: @escaping (Transformee, IndexPath) -> Item) -> CellConfigurator<Cell, Transformee> {
		CellConfigurator<Cell, Transformee>(
			cellInfo: cellInfo,
			size: { [size] in size(transform($0, $1), $1, $2) },
			configure: { [configure] in configure($0, transform($1, $2), $2, $3) },
			didSelect: { [didSelect] in didSelect($0, transform($1, $2), $2, $3) }
		)
	}
}

extension CellConfigurator: TableCellConfiguratorType where Cell: UITableViewCell {
	public var itemType: Any.Type { Item.self }

	public func asAny() -> CellConfigurator<UITableViewCell, Any> {
		CellConfigurator<UITableViewCell, Any>(
			cellInfo: cellInfo,
			size: {
				guard let item = $0 as? Item else { fatalError() }
				return self.size(item, $1, $2)
			},
			configure: {
				guard let cell = $0 as? Cell, let item = $1 as? Item else { return }
				self.configure(cell, item, $2, $3)
			},
			didSelect: { cell, item, indexPath, container in
				guard let cell = cell as? Cell, let item = item as? Item else { return }
				self.didSelect(cell, item, indexPath, container)
			}
		)
	}
}

extension CellConfigurator: CollectionCellConfiguratorType where Cell: UICollectionViewCell {
	public var itemType: Any.Type { Item.self }

	public func asAny() -> CellConfigurator<UICollectionViewCell, Any> {
		CellConfigurator<UICollectionViewCell, Any>(
			cellInfo: cellInfo,
			size: {
				guard let item = $0 as? Item else { fatalError() }
				return self.size(item, $1, $2)
			},
			configure: {
				guard let cell = $0 as? Cell, let item = $1 as? Item else { return }
				self.configure(cell, item, $2, $3)
			},
			didSelect: { cell, item, indexPath, container in
				guard let cell = cell as? Cell, let item = item as? Item else { return }
				self.didSelect(cell, item, indexPath, container)
			}
		)
	}
}

public extension RootCellConfigurator {
	/// Combines multiple cell configurators where number of them cannot be determined statically. However cellsInfo should be known by
	/// the time of call to properly register all displayable cells
	static func combine(
		cellsInfo: Set<CellInfo>,
		access: @escaping (IndexPath) -> RootCellConfigurator
	) -> RootCellConfigurator {
		RootCellConfigurator<Cell>(
			cellsInfo: cellsInfo,
			reuseID: { access($0).reuseID($0) },
			size: { access($0).size($0, $1) },
			configure: { access($1).configure($0, $1, $2) },
			didSelect: { access($1).didSelect($0, $1, $2) }
		)
	}

	static func item<ConcreteCell, Item>(
		item: Item,
		configurator: CellConfigurator<ConcreteCell, Item>
	) -> RootCellConfigurator where ConcreteCell.RootCell == Cell {
		uniform(configurator: configurator, itemAtIndex: { _ in item })
	}

	static func uniform<ConcreteCell, Item>(
		configurator: CellConfigurator<ConcreteCell, Item>,
		itemAtIndex: @escaping (Int) -> Item
	) -> RootCellConfigurator where ConcreteCell.RootCell == Cell {
		RootCellConfigurator(
			cellsInfo: [configurator.cellInfo],
			reuseID: { _ in configurator.cellInfo.reuseID },
			size: { indexPath, container in
				configurator.size(itemAtIndex(indexPath.row), indexPath, container)
			},
			configure: { cell, indexPath, container in
				guard let cell = cell as? ConcreteCell else { return }
				configurator.configure(cell, itemAtIndex(indexPath.row), indexPath, container)
			},
			didSelect: { cell, indexPath, container in
				guard let cell = cell as? ConcreteCell else { return }
				configurator.didSelect(cell, itemAtIndex(indexPath.row), indexPath, container)
			}
		)
	}
}

extension UITableViewCell: CellProtocol {
	public typealias Container = UITableView
	public typealias Dimension = CGFloat
	public typealias RootCell = UITableViewCell
}

extension UICollectionViewCell: CellProtocol {
	public typealias Container = UICollectionView
	public typealias Dimension = CGSize
	public typealias RootCell = UICollectionViewCell
}
