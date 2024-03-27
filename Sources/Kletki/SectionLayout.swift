import UIKit

public final class SectionLayout: Layout {
	private var interitemSpacing: CGFloat = 0.0
	private var cachedAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
	private var contentBounds: CGRect = .zero

	public convenience init(
		direction: UICollectionView.ScrollDirection = .vertical,
		interitemSpacing: CGFloat = .zero
	) {
		self.init()
		scrollDirection = direction
		self.interitemSpacing = interitemSpacing
	}

	override public var collectionViewContentSize: CGSize {
		contentBounds.size
	}

	public override func prepare() {
		guard let collectionView = collectionView, let delegate = delegate else { return }

		cachedAttributes.removeAll()
		contentBounds = .zero

		var lastFrame: CGRect = .zero
		var lastSection = 0
		for section in 0..<collectionView.numberOfSections {
			if collectionView.numberOfItems(inSection: section) == 0 {
				lastSection += 1
			}
			for item in 0..<collectionView.numberOfItems(inSection: section) {
				let indexPath = IndexPath(item: item, section: section)
				let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				let firstElement = section == lastSection && item == 0

				var frame: CGRect
				if scrollDirection == .horizontal {
					let x = firstElement ? 0 : lastFrame.maxX + interitemSpacing
					frame = CGRect(
						x: x,
						y: 0,
						width: size.width,
						height: size.height
					)
				} else {
					let y = firstElement ? 0 : lastFrame.maxY
					frame = CGRect(
						x: interitemSpacing,
						y: y,
						width: size.width,
						height: size.height
					)
				}

				lastFrame = frame
				attributes.frame = frame
				self.cachedAttributes[indexPath] = attributes
			}
		}

		contentBounds = contentBounds.union(lastFrame)
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		cachedAttributes.filter { $0.value.frame.intersects(rect) }.compactMap { $0.value }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		cachedAttributes[indexPath]
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let collectionView = collectionView else { return false }
		return !newBounds.size.equalTo(collectionView.bounds.size)
	}
}
