import UIKit

public struct ScrollEvents {
	public var didScroll: (UIScrollView) -> Void
	public var willBeginDragging: (UIScrollView) -> Void
	public var willEndDragging: (UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void
	public var didEndDragging: (UIScrollView, Bool) -> Void
	public var willBeginDecelerating: (UIScrollView) -> Void
	public var didEndDecelerating: (UIScrollView) -> Void
}

public extension ScrollEvents {

	static var empty: ScrollEvents = .create()

	static func create(
		didScroll: ((UIScrollView) -> Void)? = nil,
		willBeginDragging: ((UIScrollView) -> Void)? = nil,
		willEndDragging: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)? = nil,
		didEndDragging: ((UIScrollView, Bool) -> Void)? = nil,
		willBeginDecelerating: ((UIScrollView) -> Void)? = nil,
		didEndDecelerating: ((UIScrollView) -> Void)? = nil
	) -> ScrollEvents {

		ScrollEvents(
			didScroll: didScroll ?? { _ in },
			willBeginDragging: willBeginDragging ?? { _ in },
			willEndDragging: willEndDragging ?? { _, _, _ in },
			didEndDragging: didEndDragging ?? { _, _ in },
			willBeginDecelerating: willBeginDecelerating ?? { _ in },
			didEndDecelerating: didEndDecelerating ?? { _ in }
		)
	}
}

public class ScrollViewDelegate: NSObject {
	public var scrolling = [] as [ScrollEvents]
	public init(scrolling: [ScrollEvents] = []) { self.scrolling = scrolling }
}

extension ScrollViewDelegate: UIScrollViewDelegate {

	public final func scrollViewDidScroll(_ scrollView: UIScrollView) {
		scrolling.forEach { scrolling in scrolling.didScroll(scrollView) }
	}
	public final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		scrolling.forEach { scrolling in scrolling.willBeginDragging(scrollView) }
	}
	public final func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		scrolling.forEach { scrolling in scrolling.willEndDragging(scrollView, velocity, targetContentOffset) }
	}
	public final func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		scrolling.forEach { scrolling in scrolling.didEndDragging(scrollView, decelerate) }
	}
	public final func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		scrolling.forEach { scrolling in scrolling.willBeginDecelerating(scrollView) }
	}
	public final func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		scrolling.forEach { scrolling in scrolling.didEndDecelerating(scrollView) }
	}
}
