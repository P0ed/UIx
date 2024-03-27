import UIKit

public struct RowAnimations {
	var run: (UITableView, [ModelChange]) -> Void
}

public struct CellAnimations {
	var run: (UICollectionView, [ModelChange]) -> Void
}

public extension RowAnimations {

	static let none = RowAnimations { tableView, changes in
		tableView.reloadData()
	}

	static let `default` = make()

	static func make(deletes: UITableView.RowAnimation = .fade, inserts: UITableView.RowAnimation = .fade, updates: UITableView.RowAnimation = .fade) -> RowAnimations {
		RowAnimations { tableView, changes in
			guard tableView.window != nil, !changes.isEmpty else { return tableView.reloadData() }

			tableView.beginUpdates()
			changes.forEach { change in
				switch change {
				case let .delete(indexPath) where indexPath.count == 1:
					tableView.deleteSections([indexPath[0]], with: deletes)
				case let .delete(indexPath) where indexPath.count == 2:
					tableView.deleteRows(at: [indexPath], with: deletes)
				case let .insert(indexPath) where indexPath.count == 1:
					tableView.insertSections([indexPath[0]], with: inserts)
				case let .insert(indexPath) where indexPath.count == 2:
					tableView.insertRows(at: [indexPath], with: inserts)
				case let .update(indexPath) where indexPath.count == 1:
					tableView.reloadSections([indexPath[0]], with: updates)
				case let .update(indexPath) where indexPath.count == 2:
					tableView.reloadRows(at: [indexPath], with: updates)
				case let .move(from, to) where from.count == 1 && to.count == 1:
					tableView.moveSection(from[0], toSection: to[0])
				case let .move(from, to) where from.count == 2 && to.count == 2:
					tableView.moveRow(at: from, to: to)
				default: break
				}
			}
			tableView.endUpdates()
		}
	}
}

public extension CellAnimations {

	static let none = CellAnimations { collectionView, changes in
		collectionView.reloadData()
	}

	static let `default` = CellAnimations { collectionView, changes in
		guard collectionView.window != nil, !changes.isEmpty else { return collectionView.reloadData() }

		var reloadIndexPaths: [IndexPath] = []

		collectionView.performBatchUpdates({
			changes.forEach { change in
				switch change {
				case let .delete(indexPath) where indexPath.count == 1:
					collectionView.deleteSections([indexPath[0]])
				case let .delete(indexPath) where indexPath.count == 2:
					collectionView.deleteItems(at: [indexPath])
				case let .insert(indexPath) where indexPath.count == 1:
					collectionView.insertSections([indexPath[0]])
				case let .insert(indexPath) where indexPath.count == 2:
					collectionView.insertItems(at: [indexPath])
				case let .update(indexPath):
					reloadIndexPaths.append(indexPath)
				case let .move(from, to) where from.count == 1 && to.count == 1:
					collectionView.moveSection(from[0], toSection: to[0])
				case let .move(from, to) where from.count == 2 && to.count == 2:
					collectionView.moveItem(at: from, to: to)
				default: break
				}
			}
		})

		reloadIndexPaths.forEach { indexPath in
			if indexPath.count == 1 {
				collectionView.reloadSections([indexPath[0]])
			}
			if indexPath.count == 2 {
				collectionView.reloadItems(at: [indexPath])
			}
		}
	}
}
