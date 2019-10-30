//
//  SelfSizedCollectionViewLayout.swift
//  MakeMaker
//
//  Created by lynx on 07/06/2017.
//  Copyright © 2017 Zerotech. All rights reserved.
//

import UIKit

class SelfSizedCollectionViewLayout: UICollectionViewFlowLayout {
    private let numberOfColumns: Int
    private let cellPadding: CGFloat
    
    init(numberOfColumns: Int, cellPadding: CGFloat = 6) {
        self.numberOfColumns = numberOfColumns
        self.cellPadding = cellPadding
        super.init()
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        scrollDirection = .vertical
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.numberOfColumns = 1
        self.cellPadding = 6
        super.init(coder: aDecoder)
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        scrollDirection = .vertical
    }
    
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        let width = collectionView!.bounds.width - (insets.left + insets.right + sectionInset.left + sectionInset.right)
        return width
    }
    
    func getItemWidth()->CGFloat{
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        let width = columnWidth - cellPadding * 2
        return width
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath as IndexPath)?.copy() as? UICollectionViewLayoutAttributes
        guard collectionView != nil else { return attributes }
        attributes?.bounds.size.width = getItemWidth()
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let allAttributes = super.layoutAttributesForElements(in: rect)
        return allAttributes?.compactMap { attributes in
            switch attributes.representedElementCategory {
            case .cell: return layoutAttributesForItem(at: attributes.indexPath)
            default: return attributes
            }
        }
    }
}
