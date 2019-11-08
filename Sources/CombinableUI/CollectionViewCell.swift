#if canImport(UIKit)

import Combine
import UIKit

open class CombinableCollectionViewCell: UICollectionViewCell {
    public var cancellables = Set<AnyCancellable>()

    open override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}

#endif
