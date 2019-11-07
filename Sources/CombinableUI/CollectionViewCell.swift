#if canImport(UIKit)

import Combine
import UIKit

class CombinableCollectionViewCell: UICollectionViewCell {
    var cancellables = Set<AnyCancellable>()

    override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}

#endif
