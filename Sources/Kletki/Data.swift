import Foundation

public typealias ChangesResponder = ([ModelChange]) -> Void
public typealias ChangesGenerator = (@escaping ChangesResponder) -> Void

/// Represens model change
public enum ModelChange: Hashable {
	case insert(IndexPath)
	case update(IndexPath)
	case delete(IndexPath)
	case move(IndexPath, IndexPath)
}

/// CollectionIndices is represents an arbitrary repository where number of sections and number of items in each section can be determined
/// while it's being displayed but does not provide items to present
public struct CollectionIndices {
	public var numberOfSections: () -> Int
	public var numberOfItemsInSection: (Int) -> Int

	/// Closure that generates model changes and feeds the argument. Your argument is ChangeAccepter which receives an array of changes and
	/// responds accordingly.
	public var changesGenerator: ChangesGenerator
}

public extension CollectionIndices {
	/// Section represents an arbitrary repository where number of items can be determined while it's being displayed but does not provide
	/// items to present them.
	struct Section {
		/// Determines number of items
		public var numberOfItems: () -> Int

		/// Closure that generates model changes and feeds the argument. Your argument is ChangeAccepter which receives an array of changes and
		/// responds accordingly.
		public var changesGenerator: ChangesGenerator

		public init(numberOfItems: @escaping () -> Int, changesGenerator: @escaping ChangesGenerator) {
			self.numberOfItems = numberOfItems
			self.changesGenerator = changesGenerator
		}
	}

	/// Constructs CollectionIndices from an array of Section.
	static func sections(_ sections: [Section]) -> CollectionIndices {
		CollectionIndices(
			numberOfSections: { [count = sections.count] in count },
			numberOfItemsInSection: { idx in sections[idx].numberOfItems() },
			changesGenerator: { changesAccepter in
				/// Sections by default sends changes with section index 0, CollectionIndices conforms that to index of the each Section
				sections.enumerated().forEach { idx, section in
					section.changesGenerator { changes in
						changesAccepter(changes.map { change in
							change.replacingSection(idx)
						})
					}
				}
			}
		)
	}

	/// Constructs CollectionRepository from single Section
	static func section(_ section: Section) -> CollectionIndices {
		CollectionIndices(
			numberOfSections: { 1 },
			numberOfItemsInSection: { idx in idx == 0 ? section.numberOfItems() : 0 },
			changesGenerator: section.changesGenerator
		)
	}
}

public extension CollectionIndices.Section {
	/// Creates a Section from an array of items. Never changes so changesGenerator is empty closure
	static func const(_ rows: [Any]) -> CollectionIndices.Section {
		CollectionIndices.Section(
			numberOfItems: { [count = rows.count] in count },
			changesGenerator: { _ in }
		)
	}

	/// Overrides didChange notifications
	mutating func overrideChanges(_ overrides: @escaping ([ModelChange]) -> [ModelChange]?) {
		changesGenerator = { [changesGenerator] send in
			changesGenerator { overrides($0).map(send) }
		}
	}

	mutating func ignoreUpdates() {
		overrideChanges { changes in
			if changes.isEmpty { return [] }
			let filtered = changes.filter { if case .update = $0 { return false } else { return true } }
			return filtered.isEmpty ? nil : filtered
		}
	}
}

public extension CollectionIndices {
	var isEmpty: Bool {
		(0..<numberOfSections()).first(where: { numberOfItemsInSection($0) != 0 }) == nil
	}
}

public extension CollectionIndices.Section {
	var isEmpty: Bool {
		numberOfItems() == 0
	}
}

public protocol SectionDataRepresentable {
	associatedtype Item
	var sectionData: SectionData<Item> { get }
}

/// SectionData represents a typed repository of items and every item can be accessed by its index.
public struct SectionData<Item> {

	/// To get number of items and feed changes
	public var indices: CollectionIndices.Section

	/// Item at index
	public var itemAtIndex: (Int) -> Item

	public init(indices: CollectionIndices.Section, itemAtIndex: @escaping (Int) -> Item) {
		self.indices = indices
		self.itemAtIndex = itemAtIndex
	}
}

public func map<A, B>(_ transform: @escaping (A) -> B) -> (SectionData<A>) -> SectionData<B> {
	{ $0.map(transform) }
}

public extension SectionData {
	/// Creates a SectionData from an array of items. Never changes
	static func const(_ rows: [Item]) -> SectionData {
		SectionData(
			indices: .const(rows),
			itemAtIndex: { idx in rows[idx] }
		)
	}
	static var empty: SectionData { const([]) }
}

public extension SectionData {
	var isEmpty: Bool { indices.isEmpty }
	var allItems: [Item] { (0..<indices.numberOfItems()).map(itemAtIndex) }
}

extension ModelChange {
	/// Replaces underlying section index with provided one keeping the row.
	func replacingSection(_ index: Int) -> ModelChange {
		switch self {
		case let .insert(path): return .insert([index, path.item])
		case let .update(path): return .update([index, path.item])
		case let .delete(path): return .delete([index, path.item])
		case let .move(from, to): return .move([index, from.item], [index, to.item])
		}
	}
}

public extension SectionData {

	/// Creats an instance of SectionData where map function applied to every item when it's accessed
	func map<B>(_ f: @escaping (Item) -> B) -> SectionData<B> {
		SectionData<B>(indices: indices, itemAtIndex: { [itemAtIndex] idx in f(itemAtIndex(idx)) })
	}

	func enumerated() -> SectionData<(index: Int, item: Item)> {
		.init(indices: indices) { [itemAtIndex] idx in
			(idx, itemAtIndex(idx))
		}
	}

	/// Adds cache layer for expensive itemAtIndex calls e.g. caused by SectionData.map. Can be memory intensive.
	func cachedItemAccess() -> SectionData {
		var cache = Array(repeating: Item?.none, count: indices.numberOfItems())
		var data = self
		data.indices.overrideChanges { [numberOfItems = data.indices.numberOfItems] changes in
			if changes.count == 1, case let .update(idx) = changes[0] {
				cache[idx.item] = nil
			} else {
				cache = Array(repeating: Item?.none, count: numberOfItems())
			}
			return changes
		}
		data.itemAtIndex = { [itemAtIndex = data.itemAtIndex] idx in
			cache[idx] ?? {
				let item = itemAtIndex(idx)
				cache[idx] = item
				return item
			}()
		}
		return data
	}

	/// Filters the items in SectionData while accessing
	func filter(_ condition: @escaping (Item) -> Bool) -> SectionData {
		let filterState = FilterState<Item>(from: self, andFilter: condition)

		let section = CollectionIndices.Section(numberOfItems: filterState.numberOfItems, changesGenerator: filterState.forwardChanges)
		return SectionData(indices: section, itemAtIndex: filterState.item)
	}

	func sorted(_ f: @escaping (Item, Item) -> Bool) -> SectionData {
		let sort = {
			self.allItems.enumerated()
				.sorted { f($0.element, $1.element) }
				.map { $0.offset }
		}
		var sortedIndices = sort()

		return SectionData(
			indices: CollectionIndices.Section(
				numberOfItems: self.indices.numberOfItems,
				changesGenerator: { feedback in
					self.indices.changesGenerator { _ in
						sortedIndices = sort()
						feedback([])
					}
				}
			),
			itemAtIndex: { self.itemAtIndex(sortedIndices[$0]) }
		)
	}
}

/// Filtering requires complex logic as it handles incremental changes
private final class FilterState<Item> {

	init(from data: SectionData<Item>, andFilter filter: @escaping (Item) -> Bool) {
		self.proxiedData = data
		self.filter = filter

		data.indices.changesGenerator { [weak self] changes in
			self?.handle(changes: changes)
		}

		recheckAll()
	}

	private var forwardedResponder: ChangesResponder = { _ in }
	private var droppedIndexes: Set<Int> = []
	private let proxiedData: SectionData<Item>

	private let filter: (Item) -> Bool

	private func handle(changes: [ModelChange]) {
		recheckAll()
		forwardedResponder([])
	}

	private func recheckAll() {
		droppedIndexes.removeAll()

		(0..<proxiedData.indices.numberOfItems())
			.map(proxiedData.itemAtIndex)
			.enumerated()
			.filter { !filter($0.element) }
			.forEach { droppedIndexes.insert($0.offset) }
	}

	func item(at index: Int) -> Item {
		var index = index
		while droppedIndexes.contains(index) {
			index += 1
		}

		return proxiedData.itemAtIndex(index)
	}

	func numberOfItems() -> Int {
		max(proxiedData.indices.numberOfItems() - droppedIndexes.count, 0)
	}

	func forwardChanges(to responder: @escaping ChangesResponder) {
		forwardedResponder = responder
	}
}
