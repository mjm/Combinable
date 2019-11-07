#if canImport(UIKit)

import Combine
import UIKit

public class CombinableCollectionViewDataSource<
    SectionIdentifierType: Hashable,
    ItemIdentifierType: ReusableCell
>: UICollectionViewDiffableDataSource<
    SectionIdentifierType,
    ItemIdentifierType
>, DiffableSnapshotApplying
where ItemIdentifierType.Identifier.CellType == UICollectionViewCell {
    public var cancellables = Set<AnyCancellable>()

    public init(
        _ collectionView: UICollectionView,
        configureCell: @escaping (UICollectionViewCell, ItemIdentifierType) -> Void
    ) {
        ItemIdentifierType.register(with: collectionView)

        super.init(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: item.cellIdentifier.rawValue, for: indexPath)
            configureCell(cell, item)
            return cell
        }
    }

    public typealias SupplementaryViewProviderWithType = (
        UICollectionView, String, IndexPath, SectionIdentifierType
    ) -> UICollectionReusableView?

    public func withSupplementaryViews(_ viewProvider: @escaping SupplementaryViewProviderWithType) -> Self
    {
        self.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.snapshot().sectionIdentifiers[indexPath.section]
            else {
                return nil
            }

            return viewProvider(collectionView, kind, indexPath, section)
        }

        return self
    }
}

extension CombinableCollectionViewDataSource where ItemIdentifierType: BindableCell {
    public convenience init(_ collectionView: UICollectionView) {
        self.init(collectionView) { cell, item in
            item.bind(to: cell)
        }
    }
}

#endif
