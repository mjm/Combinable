#if canImport(UIKit)

import Combine
import UIKit

public class CombinableTableViewDataSource<
    SectionIdentifierType: Hashable,
    ItemIdentifierType: ReusableCell
>: UITableViewDiffableDataSource<
    SectionIdentifierType,
    ItemIdentifierType
>, DiffableSnapshotApplying
where ItemIdentifierType.Identifier.CellType == UITableViewCell {
    public var cancellables = Set<AnyCancellable>()

    public init(
        _ tableView: UITableView,
        configureCell: @escaping (UITableViewCell, ItemIdentifierType) -> Void
    ) {
        ItemIdentifierType.register(with: tableView)

        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: item.cellIdentifier.rawValue, for: indexPath)
            configureCell(cell, item)
            return cell
        }
    }

    public func editable(_ canEditRow: @escaping CanEditProvider = { _, _, _ in true }) -> Self {
        self.canEditRow = canEditRow
        return self
    }

    public func withSectionTitles(_ titleProvider: @escaping SectionTitleProvider) -> Self {
        self.sectionTitle = titleProvider
        return self
    }

    public func withSectionTitles(_ titles: [SectionIdentifierType: String]) -> Self {
        self.sectionTitle = { _, _, section in titles[section] }
        return self
    }

    public typealias CanEditProvider = (UITableView, IndexPath, ItemIdentifierType) -> Bool
    public typealias SectionTitleProvider = (UITableView, Int, SectionIdentifierType) -> String?

    var canEditRow: CanEditProvider = { (_, _, _) in false }

    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let item = itemIdentifier(for: indexPath) else { return false }
        return canEditRow(tableView, indexPath, item)
    }

    var sectionTitle: SectionTitleProvider = { (_, _, _) in nil }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
        -> String?
    {
        let sectionIdentifier = snapshot().sectionIdentifiers[section]
        return sectionTitle(tableView, section, sectionIdentifier)
    }
}

extension CombinableTableViewDataSource where ItemIdentifierType: BindableCell {
    public convenience init(_ tableView: UITableView) {
        self.init(tableView) { cell, item in
            item.bind(to: cell)
        }
    }
}

#endif
