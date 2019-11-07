#if canImport(UIKit)

import Combine
import UIKit

public class CombinableTableViewCell: UITableViewCell {
    @Published var _selected: Bool = false
    @Published var _highlighted: Bool = false

    public var cancellables = Set<AnyCancellable>()

    public var selectedOrHighlighted: AnyPublisher<Bool, Never> {
        $_selected.combineLatest($_highlighted) { selected, highlighted in
            selected || highlighted
        }.eraseToAnyPublisher()
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        _selected = selected
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        _highlighted = highlighted
    }

    public override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}

#endif
