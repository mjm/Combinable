#if canImport(UIKit)

import Combine
import UIKit

public class CombinableCollectionViewCell: UICollectionViewCell {
    public var cancellables = Set<AnyCancellable>()

    public override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}

#endif
