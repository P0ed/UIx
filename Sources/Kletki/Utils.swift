import UIKit

extension UIView {

	func pin(to view: UIView, edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero, priority: UILayoutPriority = .required) {
		translatesAutoresizingMaskIntoConstraints = false

		let top = edges.contains(.top) ? topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top) : nil
		top?.priority = priority
		let left = edges.contains(.left) ? leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left) : nil
		left?.priority = priority
		let bottom = edges.contains(.bottom) ? bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom) : nil
		bottom?.priority = priority
		let right = edges.contains(.right) ? trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right) : nil
		right?.priority = priority

		NSLayoutConstraint.activate([top, left, bottom, right].compactMap { $0 })
	}
}

extension UILayoutPriority {
	static var collectionRequired: UILayoutPriority { UILayoutPriority(UILayoutPriority.required.rawValue - 1) }
}
