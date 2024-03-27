import UIKit

public final class HorizontalPickerLayout: Layout {
	private let interitemSpacing: CGFloat
	private let lineSpacing: CGFloat
	private let scaleRate: CGFloat

	private var cachedAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
	private var contentBounds: CGRect = .zero

	public init(
		scaleRate: CGFloat = 0.6,
		interitemSpacing: CGFloat = .zero,
		lineSpacing: CGFloat = .zero
	) {
		self.interitemSpacing = interitemSpacing
		self.lineSpacing = lineSpacing
		self.scaleRate = scaleRate
		super.init()
		self.scrollDirection = .horizontal
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
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
		var leftInset: CGFloat = 0
		var rightInset: CGFloat = 0

		for section in 0..<collectionView.numberOfSections {
			if collectionView.numberOfItems(inSection: section) == 0 {
				lastSection += 1
			}
			for item in 0..<collectionView.numberOfItems(inSection: section) {
				let indexPath = IndexPath(item: item, section: section)
				let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				let firstElement = section == lastSection && item == 0
				let lastElement = section == lastSection && item == collectionView.numberOfItems(inSection: section) - 1

				let inset = (collectionView.frame.width - size.width) / 2
				if firstElement  { leftInset = inset }
				if lastElement { rightInset = inset }

				let x = firstElement ? 0.0 : lastFrame.maxX + interitemSpacing
				let frame = CGRect(x: x, y: 0, width: size.width, height: size.height)
				lastFrame = frame
				attributes.frame = frame
				self.cachedAttributes[indexPath] = attributes
			}
		}

		/// Set insets for collection view so that attributes are focused in the center
		collectionView.contentInset = .init(
			top: lineSpacing,
			left: leftInset,
			bottom: lineSpacing,
			right: rightInset
		)
		contentBounds = contentBounds.union(lastFrame)
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		cachedAttributes
			.filter { $0.value.frame.intersects(rect) }
			.compactMap { $0.value.copy() as? UICollectionViewLayoutAttributes }
			.map { transformLayoutAttributes($0) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		cachedAttributes[indexPath]
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		true
	}

	/// Saving collectionView contentOffset position when changing bounce
	public override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
		super.prepare(forAnimatedBoundsChange: oldBounds)
		guard let collectionView = collectionView else { return }

		/// Get `visiblePoint` with oldBounds before changes
		let visiblePoint = CGPoint(x: oldBounds.midX, y: oldBounds.midY)
		/// Get `indexPath` with `visiblePoint` before changes
		if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
			if let attributes = cachedAttributes[indexPath] {
				let x = attributes.frame.origin.x - collectionView.contentInset.left
				/// Approximate offset
				let offset = CGPoint(x: x, y: attributes.bounds.origin.y)
				/// Exact offset
				let targetOffset = targetContentOffset(forProposedContentOffset: offset, withScrollingVelocity: .zero)
				collectionView.setContentOffset(targetOffset, animated: false)
			}
		}
	}

	private func transformLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		guard let collectionView = collectionView else { return attributes }
        let layoutAttributes = attributes

		let size = layoutAttributes.frame.size
		let offset = layoutAttributes.frame.origin.x - (collectionView.bounds.width - size.width) / 2
		let alpha = 1 - abs((offset - collectionView.contentOffset.x) / collectionView.bounds.width)
		let scaleFactor = 1 - abs((offset - collectionView.contentOffset.x) * scaleRate / collectionView.bounds.width)

		layoutAttributes.alpha = alpha
		layoutAttributes.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
		return layoutAttributes
	}

	public override func targetContentOffset(
		forProposedContentOffset proposedContentOffset: CGPoint,
		withScrollingVelocity velocity: CGPoint
	) -> CGPoint {
		guard let collectionView = collectionView else {
			return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
		}
		let midX: CGFloat = collectionView.bounds.size.width / 2
		let x = proposedContentOffset.x + midX
		let searchRect = CGRect(
			x: x - collectionView.bounds.width, y: collectionView.bounds.minY,
			width: collectionView.bounds.width * 2, height: collectionView.bounds.height
		)
		let attributes = layoutAttributesForElements(in: searchRect)
		if let closestAttributes = attributes?.min(by: { abs($0.center.x - x) < abs($1.center.x - x) }) {
			return CGPoint(x: closestAttributes.center.x - midX, y: proposedContentOffset.y)
		}
		return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
	}
}

extension HorizontalPickerLayout {
	private static var lastIndex: Int?

	public static func didCross(_ didCross: @escaping () -> Void) -> ScrollEvents {
		.create(didScroll: { scrollView in
			guard let collectionView = scrollView as? UICollectionView else { return }
			let midX = scrollView.bounds.midX
			let crossFactor: CGFloat = 8
			collectionView.indexPathsForVisibleItems.forEach { indexPath in
				if let cell = collectionView.cellForItem(at: indexPath) {
					let cellMidX = cell.frame.midX
					if cellMidX + crossFactor >= midX && cellMidX - crossFactor <= midX && lastIndex != indexPath.item {
						lastIndex = indexPath.item
						didCross()
					} else if lastIndex == indexPath.item, cellMidX + (crossFactor * 2) <= midX || cellMidX - (crossFactor * 2) >= midX {
						lastIndex = nil
					}
				}
			}
		})
	}

	public static func didEnd(_ didEnd: @escaping (IndexPath) -> Void) -> ScrollEvents {
		.didEndInteraction({ scrollView in
			guard let collectionView = scrollView as? UICollectionView else { return }
			let midX = scrollView.bounds.midX
			let crossFactor: CGFloat = 8
			collectionView.indexPathsForVisibleItems.forEach { indexPath in
				if let cell = collectionView.cellForItem(at: indexPath) {
					let cellMidX = cell.frame.midX
					if cellMidX + crossFactor >= midX && cellMidX - crossFactor <= midX {
						didEnd(indexPath)
					}
				}
			}
		})
	}
}
