import UIKit

public class LeftAlignedLayout: Layout {
	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		let attributes = super.layoutAttributesForElements(in: rect)?.filter { $0.frame.intersects(rect) }
		guard let attributesInRect = attributes else { return nil }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributesInRect.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        return attributesInRect
    }
}
