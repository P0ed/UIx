import UIKit

open class Layout: UICollectionViewFlowLayout {
	weak var delegate: UICollectionViewDelegateFlowLayout?

	public convenience init(
		direction: UICollectionView.ScrollDirection = .vertical,
		interitemSpacing: CGFloat = .zero,
		lineSpacing: CGFloat = .zero
	) {
		self.init()
		scrollDirection = direction
		minimumInteritemSpacing = interitemSpacing
		minimumLineSpacing = lineSpacing
	}

	override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		true
	}

	override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		let ctx = super.invalidationContext(forBoundsChange: newBounds)

		if let flowCtx = ctx as? UICollectionViewFlowLayoutInvalidationContext, let bounds = collectionView?.bounds {
			flowCtx.invalidateFlowLayoutDelegateMetrics = bounds != newBounds
		}

		return ctx
	}
}
