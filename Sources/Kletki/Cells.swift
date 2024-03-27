import UIKit

public final class Cells: UIView {
	public typealias Model = CollectionModel<UICollectionViewCell>

	public let model: CollectionModel<UICollectionViewCell>
	public let collectionView: UICollectionView

	public var scrolling: [ScrollEvents] {
		get { delegate.scrolling }
		set { delegate.scrolling = newValue }
	}
	public var cellDisplaying: [CellDisplaying<UICollectionViewCell>] {
		get { delegate.cellDisplaying }
		set { delegate.cellDisplaying = newValue }
	}

	public var animations = CellAnimations.default
	public var didChangeData = { _ in } as (CollectionIndices) -> Void

	public var footerView: UIView? {
		didSet {
			delegate.footerView = footerView
			collectionView.performBatchUpdates({ [collectionView] in
				collectionView.collectionViewLayout.invalidateLayout()
			})
		}
	}

	public var headerView: UIView? {
		didSet {
			delegate.headerView = headerView
			collectionView.performBatchUpdates({ [collectionView] in
				collectionView.collectionViewLayout.invalidateLayout()
			})
		}
	}

	private let delegate: Delegate

	public init(
		model: CollectionModel<UICollectionViewCell>,
		layout: UICollectionViewFlowLayout = Layout()
	) {
		self.model = model
		delegate = Delegate(model: model)

		if let layout = layout as? Layout {
			layout.delegate = delegate
		}

		collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

		super.init(frame: .zero)

		model.configurator.cellsInfo.forEach { info in collectionView.register(info.type, forCellWithReuseIdentifier: info.reuseID) }
		model.indices.changesGenerator { [weak self] changes in
			guard let self = self else { return }
			self.animations.run(self.collectionView, changes)
			self.didChangeData(self.model.indices)
		}

		collectionView.register(
			ReusableView.self,
			forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
			withReuseIdentifier: ReusableView.reuseID
		)
		collectionView.register(
			ReusableView.self,
			forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
		    withReuseIdentifier: ReusableView.reuseID
		)

		collectionView.delegate = delegate
		collectionView.dataSource = delegate

		addSubview(collectionView)
		collectionView.pin(to: self)
	}

	public required init?(coder: NSCoder) { fatalError() }
}

private final class ReusableView: UICollectionReusableView {
	static let reuseID = "Kletki.ReusableView"
	var contentView: UIView? {
		didSet {
			oldValue?.removeFromSuperview()
			if let view = contentView {
				view.translatesAutoresizingMaskIntoConstraints = false
				addSubview(view)

				addConstraints([
					leadingAnchor.constraint(equalTo: view.leadingAnchor),
					topAnchor.constraint(equalTo: view.topAnchor),
					trailingAnchor.constraint(equalTo: view.trailingAnchor),
					bottomAnchor.constraint(equalTo: view.bottomAnchor)
				])
			}
		}
	}
}

private final class Delegate: ScrollViewDelegate {
	private let model: CollectionModel<UICollectionViewCell>

	var cellDisplaying = [] as [CellDisplaying<UICollectionViewCell>]

	var footerView: UIView?
	var headerView: UIView?

	init(model: CollectionModel<UICollectionViewCell>) {
		self.model = model
	}
}

extension Delegate: UICollectionViewDelegate {

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let cell = collectionView.cellForItem(at: indexPath) else { return }
		model.configurator.didSelect(cell, indexPath, collectionView)
	}

	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		model.configurator.configure(cell, indexPath, collectionView)
		cellDisplaying.forEach { $0.willDisplay(collectionView, cell, indexPath) }
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		model.configurator.teardown(cell, indexPath, collectionView)
		cellDisplaying.forEach { $0.didEndDisplaying(collectionView, cell, indexPath) }
	}
}

extension Delegate: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		model.configurator.size(indexPath, collectionView)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		headerView?.sizeThatFits(.zero) ?? .zero
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		section == model.indices.numberOfSections() - 1 ? footerView?.bounds.size ?? .zero : .zero
	}
}

extension Delegate: UICollectionViewDataSource {

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		model.indices.numberOfSections()
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		model.indices.numberOfItemsInSection(section)
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let id = model.configurator.reuseID(indexPath)
		return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
	}

	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReusableView.reuseID, for: indexPath)

		switch kind {
		case UICollectionView.elementKindSectionHeader:
			(view as? ReusableView)?.contentView = headerView
		default:
			(view as? ReusableView)?.contentView = footerView
		}

		return view
	}
}
