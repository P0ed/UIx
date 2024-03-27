import UIKit

public struct Cell<Model> {
	public var body: UIView
	public var setModel: (Model) -> Void
	public var reuse: () -> Void
	public var selectionStyle: UITableViewCell.SelectionStyle

	public init(
		body: UIView,
		setModel: @escaping (Model) -> Void,
		reuse: @escaping () -> Void = {},
		selectionStyle: UITableViewCell.SelectionStyle = .none
	) {
		self.body = body
		self.setModel = setModel
		self.reuse = reuse
		self.selectionStyle = selectionStyle
	}
}

public protocol GenericCellConstructor {
	associatedtype Model
	static func makeCell() -> Cell<Model>

	static func didSelect(item: Model, at indexPath: IndexPath)
}

public final class GenericRow<CellConstructor: GenericCellConstructor>: UITableViewCell {
	public let body: UIView
	public let setModel: (CellConstructor.Model) -> Void
	public let reuse: () -> Void

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		let cell = CellConstructor.makeCell()
		body = cell.body
		setModel = cell.setModel
		reuse = cell.reuse

		super.init(style: style, reuseIdentifier: reuseIdentifier)

		selectionStyle = cell.selectionStyle
		contentView.addSubview(cell.body)
		cell.body.pin(to: contentView, priority: .required)
	}

	required init?(coder: NSCoder) { fatalError() }

	public override func prepareForReuse() { reuse() }
}

public final class GenericCell<View: GenericCellConstructor>: UICollectionViewCell {
	public let body: UIView
	public let setModel: (View.Model) -> Void
	public let reuse: () -> Void

	public override init(frame: CGRect) {
		let cell = View.makeCell()
		body = cell.body
		setModel = cell.setModel
		reuse = cell.reuse

		super.init(frame: frame)

		contentView.addSubview(cell.body)
		cell.body.pin(to: contentView)
	}

	public required init?(coder: NSCoder) { fatalError() }

	public override func prepareForReuse() { reuse() }
}

public extension GenericCellConstructor {

	static func didSelect(item: Model, at indexPath: IndexPath) {}

	static func rowConfigurator(
		didSelect: @escaping (GenericRow<Self>, Self.Model, IndexPath, UITableView) -> Void = { _, item, indexPath, _ in didSelect(item: item, at: indexPath) }
	) -> CellConfigurator<GenericRow<Self>, Model> {
		.autoHeight(
			configure: { cell, model, _, _ in
				cell.setModel(model)
			},
			didSelect: didSelect
		)
	}

	static func rowConfigurator(
		height: @escaping (Self.Model, IndexPath, UITableView) -> CGFloat,
		didSelect: @escaping (GenericRow<Self>, Self.Model, IndexPath, UITableView) -> Void = { _, item, indexPath, _ in didSelect(item: item, at: indexPath) }
	) -> CellConfigurator<GenericRow<Self>, Model> {
		CellConfigurator(
			size: height,
			configure: { cell, model, _, _ in
				cell.setModel(model)
			},
			didSelect: didSelect
		)
	}

	static func cellConfigurator(
		size: @escaping (Model, IndexPath, UICollectionViewCell.Container) -> CGSize,
		didSelect: @escaping (GenericCell<Self>, Self.Model, IndexPath, UICollectionViewCell.Container) -> Void = { _, item, indexPath, _ in didSelect(item: item, at: indexPath) }
	) -> CellConfigurator<GenericCell<Self>, Model> {
		CellConfigurator(
			size: { model, indexPath, container in size(model, indexPath, container) },
			configure: { cell, model, _, _ in
				cell.setModel(model)
			},
			didSelect: didSelect
		)
	}
}
