import UIKit

public final class Rows: UIView {
	public typealias Model = CollectionModel<UITableViewCell>

	public let model: Model
	public let tableView: UITableView

	public var scrolling: [ScrollEvents] {
		get { delegate.scrolling }
		set { delegate.scrolling = newValue }
	}
	public var cellDisplaying: [CellDisplaying<UITableViewCell>] {
		get { delegate.cellDisplaying }
		set { delegate.cellDisplaying = newValue }
	}
	public var removesSelection: Bool {
		get { delegate.removesSelection }
		set { delegate.removesSelection = newValue }
	}

	public var animations = RowAnimations.default
	public var didChangeData = { _ in } as (CollectionIndices) -> Void

	private let delegate: Delegate

	public init(model: Model, style: UITableView.Style = .plain) {
		self.model = model
		delegate = Delegate(model: model)
		tableView = UITableView(frame: .zero, style: style)

		super.init(frame: .zero)

		model.configurator.cellsInfo.forEach { info in tableView.register(info.type, forCellReuseIdentifier: info.reuseID) }
		model.indices.changesGenerator { [weak self] changes in
			guard let self = self else { return }
			self.animations.run(self.tableView, changes)
			self.didChangeData(self.model.indices)
		}

		tableView.separatorStyle = .none
		tableView.delegate = delegate
		tableView.dataSource = delegate
		tableView.tableFooterView = UIView()

		addSubview(tableView)
		tableView.pin(to: self)
	}

	public required init?(coder: NSCoder) { fatalError() }
}

private final class Delegate: ScrollViewDelegate {
	private let model: Rows.Model

	var cellDisplaying = [] as [CellDisplaying<UITableViewCell>]
	var removesSelection = true

	init(model: CollectionModel<UITableViewCell>) {
		self.model = model
	}
}

extension Delegate: UITableViewDelegate {

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else { return }
		if removesSelection { tableView.deselectRow(at: indexPath, animated: true) }
		model.configurator.didSelect(cell, indexPath, tableView)
	}

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let height = tableView.estimatedRowHeight
		return height != 0 ? height : model.configurator.size(indexPath, tableView)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		model.configurator.size(indexPath, tableView)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		model.configurator.configure(cell, indexPath, tableView)
		cellDisplaying.forEach { $0.willDisplay(tableView, cell, indexPath) }
	}

	func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		model.configurator.teardown(cell, indexPath, tableView)
		cellDisplaying.forEach { $0.didEndDisplaying(tableView, cell, indexPath) }
	}
}

extension Delegate: UITableViewDataSource {

	func numberOfSections(in tableView: UITableView) -> Int {
		model.indices.numberOfSections()
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		model.indices.numberOfItemsInSection(section)
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let id = model.configurator.reuseID(indexPath)
		return tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
	}
}
