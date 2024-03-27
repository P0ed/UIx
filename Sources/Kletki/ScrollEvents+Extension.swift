import UIKit

public extension ScrollEvents {
	static func didEndInteraction(_ didEnd: @escaping (UIScrollView) -> Void) -> ScrollEvents {
		.create(
			didEndDragging: { scrollView, willDecelerate in
				if willDecelerate == false {
					didEnd(scrollView)
				}
			},
			didEndDecelerating: { scrollView in
				didEnd(scrollView)
			}
		)
	}

	static func didEndPaging(spacing: CGFloat = .zero, _ didEnd: @escaping (Int) -> Void) -> ScrollEvents {
		.didEndInteraction { scrollView in
			let pageWidth = (scrollView.frame.width - scrollView.contentInset.left - scrollView.contentInset.right) + spacing
			let page = Int(round(scrollView.contentOffset.x / pageWidth))
			didEnd(page)
		}
	}

	static func willEndPaging(spacing: CGFloat = .zero, didSetApproximatePage: ((Int) -> Void)? = nil) -> ScrollEvents {
		.create(willEndDragging: { (scrollView, velocity, targetContentOffset) in
			// Page width used for estimating and calculating paging.
			let pageWidth = (scrollView.frame.width - scrollView.contentInset.left - scrollView.contentInset.right) + spacing

			// Make an estimation of the current page position.
			let approximatePage = scrollView.contentOffset.x / pageWidth

			// Determine the current page based on velocity.
			let currentPage = velocity.x == 0 ? round(approximatePage) : (velocity.x < 0.0 ? floor(approximatePage) : ceil(approximatePage))

			// Create custom flickVelocity.
			let flickVelocity = velocity.x * 0.3

			// Check how many pages the user flicked, if <= 1 then flickedPages should return 0.
			let flickedPages = (abs(round(flickVelocity)) <= 1) ? 0 : round(flickVelocity)

			didSetApproximatePage?(Int(currentPage + flickedPages))

			// Calculate newHorizontalOffset.
			let newHorizontalOffset = ((currentPage + flickedPages) * pageWidth) - scrollView.contentInset.left
			let newContentOffset = CGPoint(x: newHorizontalOffset, y: targetContentOffset.pointee.y)
			targetContentOffset.pointee = newContentOffset
		})
	}
}
