import Foundation

/// CollectionModel represents multiple section of cells without providing items. Configurators are called only providing indexPath without item
public struct CollectionModel<Cell: CellProtocol> {

	/// Single or multiple configurators merged into one
	public var configurator: RootCellConfigurator<Cell>
	public var indices: CollectionIndices

	public init(configurator: RootCellConfigurator<Cell>, indices: CollectionIndices) {
		self.configurator = configurator
		self.indices = indices
	}
}

public extension CollectionModel {

	/// Section represents section of cells whithout providing items. Configurators are called only providing indexPath without the item
	struct Section {
		/// Single or multiple configurators merged into one
		public var configurator: RootCellConfigurator<Cell>
		public var indices: CollectionIndices.Section

		public init(configurator: RootCellConfigurator<Cell>, indices: CollectionIndices.Section) {
			self.configurator = configurator
			self.indices = indices
		}
	}

	/// Creates a CollectionModel from an array of Sections mergin them into one
	static func sections(_ sections: [Self.Section]) -> CollectionModel {
		sections.count == 1 ? .section(sections[0]) : CollectionModel(
			configurator: .combine(
				cellsInfo: sections.reduce(into: []) { $0.formUnion($1.configurator.cellsInfo) },
				access: { sections[$0.section].configurator }
			),
			indices: .sections(sections.map { $0.indices })
		)
	}

	/// Creates a CellModel from a single CellSection
	static func section(_ section: Self.Section) -> CollectionModel {
		CollectionModel(
			configurator: section.configurator,
			indices: .section(section.indices)
		)
	}
}

public extension CollectionModel.Section {
	/// Creates a CellSection where item in the section can be provided for the configurator
	static func uniform<ConcreteCell, Item>(
		configurator: CellConfigurator<ConcreteCell, Item>,
		data: SectionData<Item>
	) -> CollectionModel<Cell>.Section where ConcreteCell.RootCell == Cell {
		CollectionModel<Cell>.Section(
			configurator: .uniform(configurator: configurator, itemAtIndex: data.itemAtIndex),
			indices: data.indices
		)
	}

	/// Creates a CellSection where all configurators should be shown exact once.
	static func const(data: [RootCellConfigurator<Cell>]) -> CollectionModel<Cell>.Section {
		CollectionModel.Section(
			configurator: .combine(
				cellsInfo: data.reduce(into: []) { $0.formUnion($1.cellsInfo) },
				access: { data[$0.row] }
			),
			indices: .const(data)
		)
	}

	/// Creates a CellSection for UICollectionView where each cell configurator accepts an item of known type and each item mapped to its
	/// configurator.
	static func mapped<Item>(cells: Set<CellInfo>, configurator: @escaping (Item) -> CellConfigurator<Cell, Any>, data: SectionData<Item>) -> CollectionModel<Cell>.Section {
		let itemAtIndex = data.itemAtIndex
		return CollectionModel<Cell>.Section(
			configurator: RootCellConfigurator<Cell>(
				cellsInfo: cells,
				reuseID: { indexPath in
					let item = itemAtIndex(indexPath.item)
					return configurator(item).cellInfo.reuseID
				},
				size: { indexPath, collectionView in
					let item = itemAtIndex(indexPath.item)
					return configurator(item).size(item, indexPath, collectionView)
				},
				configure: { cell, indexPath, collectionView in
					let item = itemAtIndex(indexPath.item)
					configurator(item).configure(cell, item, indexPath, collectionView)
				},
				didSelect: { cell, indexPath, collectionView in
					let item = itemAtIndex(indexPath.item)
					configurator(item).didSelect(cell, item, indexPath, collectionView)
				}
			),
			indices: data.indices
		)
	}
}
