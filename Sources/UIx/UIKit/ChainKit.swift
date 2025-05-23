import UIKit

public struct SearchPattern<A, B> {
	public var test: (A) -> B?

	public init(predicate: @escaping (A) -> B?) {
		self.test = predicate
	}

	public static func type(_ type: B.Type = B.self) -> SearchPattern {
		Self { $0 as? B }
	}

	public func and(_ predicate: @escaping (B) -> Bool) -> SearchPattern {
		Self { test($0).flatMap { predicate($0) ? $0 : nil } }
	}
}

public extension SearchPattern where A == B {

	static func filter(_ predicate: @escaping (A) -> Bool) -> SearchPattern {
		Self { predicate($0) ? $0 : nil }
	}
}

@MainActor
public extension SearchPattern where B == UIStackView {
	static func stack(_ axis: NSLayoutConstraint.Axis) -> SearchPattern {
		.type(UIStackView.self).and { $0.axis == axis }
	}
}

public extension UIResponder {
	func findResponder<A>(_ pattern: SearchPattern<UIResponder, A>) -> A? {
		pattern.test(self) ?? next?.findResponder(pattern)
	}
	func findResponder<A>(_ type: A.Type = A.self) -> A? {
		findResponder(.type(type))
	}
	func findResponderOnScreen<A>(_ pattern: SearchPattern<UIResponder, A>) -> A? {
		self is UIViewController ? nil : pattern.test(self) ?? next?.findResponderOnScreen(pattern)
	}
}

public extension UIView {
	func findSubview<A>(_ pattern: SearchPattern<UIView, A>) -> A? {
		pattern.test(self) ?? subviews.find { $0.findSubview(pattern) }
	}
	func findSubview<A>(_ type: A.Type = A.self) -> A? {
		findSubview(.type(type))
	}
}

private extension Collection {

	func find<Target>(with closure: (Element) throws -> Target?) rethrows -> Target? {
		for element in self {
			if let target = try closure(element) {
				return target
			}
		}
		return nil
	}
}
