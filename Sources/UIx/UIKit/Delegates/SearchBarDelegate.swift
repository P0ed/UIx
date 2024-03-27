import UIKit

public final class SearchBarDelegate: NSObject, UISearchBarDelegate {
	public var shouldBeginEditing: (UISearchBar) -> Bool = { _ in true }
	public var textDidBeginEditing: (UISearchBar) -> Void = { _ in }
	public var shouldEndEditing: (UISearchBar) -> Bool = { _ in true }
	public var textDidEndEditing: (UISearchBar) -> Void = { _ in }
	public var textDidChange: (UISearchBar, String) -> Void = { _, _ in }
	public var shouldChangeTextInRange: (UISearchBar, NSRange, String) -> Bool = { _, _, _ in true }
	public var searchButtonClicked: (UISearchBar) -> Void = { _ in }
	public var bookmarkButtonClicked: (UISearchBar) -> Void = { _ in }
	public var cancelButtonClicked: (UISearchBar) -> Void = { _ in }
	public var resultsListButtonClicked: (UISearchBar) -> Void = { _ in }
	public var selectedScopeButtonIndexDidChange: (UISearchBar, Int) -> Void = { _, _ in }

	public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
		shouldBeginEditing(searchBar)
	}
	public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		textDidBeginEditing(searchBar)
	}
	public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
		shouldEndEditing(searchBar)
	}
	public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		textDidEndEditing(searchBar)
	}
	public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		textDidChange(searchBar, searchText)
	}
	public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		shouldChangeTextInRange(searchBar, range, text)
	}
	public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchButtonClicked(searchBar)
	}
	public func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
		bookmarkButtonClicked(searchBar)
	}
	public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		cancelButtonClicked(searchBar)
	}
	public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
		resultsListButtonClicked(searchBar)
	}
	public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		selectedScopeButtonIndexDidChange(searchBar, selectedScope)
	}
}
