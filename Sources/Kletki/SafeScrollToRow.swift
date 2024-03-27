import UIKit

public extension UITableView {
	func isIndexPathAvailable(_ indexPath: IndexPath) -> Bool {
		guard dataSource != nil,
			indexPath.section < numberOfSections,
			indexPath.item < numberOfRows(inSection: indexPath.section)
			else { return false }

		return true
	}

	func safeScrollToRow(
		at indexPath: IndexPath,
		at scrollPosition: UITableView.ScrollPosition,
		animated: Bool
	) throws {
		guard isIndexPathAvailable(indexPath) else {
			throw Error.invalidIndexPath(indexPath: indexPath, lastIndexPath: lastIndexPath)
		}

		scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
	}

	var lastIndexPath: IndexPath {
		let lastSection = numberOfSections - 1
		return IndexPath(item: numberOfRows(inSection: lastSection) - 1, section: lastSection)
	}
}

private extension UITableView {
	enum Error: Swift.Error, CustomStringConvertible {
		case invalidIndexPath(indexPath: IndexPath, lastIndexPath: IndexPath)
		var description: String {
			switch self {
			case let .invalidIndexPath(indexPath, lastIndexPath):
				return "IndexPath \(indexPath) is not available. The last available IndexPath is \(lastIndexPath)"
			}
		}
	}
}
