#if canImport(UIKit)

import Combine
import UIKit

/// A diffable data source that supports binding to a publisher of snapshots.
///
/// The items in the data source snapshots must conform to `ReusableCell` which allows some
/// conveniences:
/// - The data source can ask the items which cell identifier they use, and dequeue a cell for them.
/// - Any NIBs or cell classes used by the items will be registered automatically with the table view.
///
/// This data source also supports some features of `UITableViewDataSource` that the built-in
/// `UITableViewDiffableDataSource` doesn't:
/// - Indicating which rows can be edited. See `editable(_:)`.
/// - Providing titles for the sections in the table view. See `titled(_:)`.
///
/// - SeeAlso: `DiffableSnapshotApplying`, which provides methods to bind a publisher
///   of snapshots to the data source.
///
public class CombinableTableViewDataSource<
    SectionIdentifierType: Hashable,
    ItemIdentifierType: ReusableCell
>: UITableViewDiffableDataSource<
    SectionIdentifierType,
    ItemIdentifierType
>, DiffableSnapshotApplying
where ItemIdentifierType.Identifier.CellType == UITableViewCell {
    /// :nodoc:
    public var cancellables = Set<AnyCancellable>()

    /// Create a new data source for a table view, populating cells with a block.
    ///
    /// The new data source will be set on the `dataSource` property of the table view.
    ///
    /// - Parameters:
    ///    - tableView: The table view the data source will populate.
    ///    - configureCell: A closure that updates the given cell with content for the given item.
    ///    - cell: The cell to be configured that the data source dequeued for the item.
    ///    - item: The item whose cell is being configured.
    ///
    public init(
        _ tableView: UITableView,
        configureCell: @escaping (_ cell: UITableViewCell, _ item: ItemIdentifierType) -> Void
    ) {
        ItemIdentifierType.register(with: tableView)

        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: item.cellIdentifier.rawValue, for: indexPath)
            configureCell(cell, item)
            return cell
        }
    }

    /// Enable editing rows in the table view.
    ///
    /// Allowing editing is required to support swipe-to-delete or custom swipe actions on the rows.
    ///
    /// - Parameters:
    ///    - canEditRow: A closure that returns a boolean indicating whether a particular row can be
    ///    edited. If not provided, all rows will be editable.
    ///
    /// - Returns: The data source, to allow continued configuration.
    ///
    public func editable(_ canEditRow: @escaping CanEditProvider = { _, _, _ in true }) -> Self {
        self.canEditRow = canEditRow
        return self
    }

    /// Add section titles to the table view using a closure.
    ///
    /// - Parameters:
    ///    - titleProvider: A closure that returns a string for the title of the given section.
    ///
    /// - Returns: The data source, to allow continued configuration.
    ///
    public func titled(_ titleProvider: @escaping SectionTitleProvider) -> Self {
        self.sectionTitle = titleProvider
        return self
    }

    /// Add section titles to the table view using a dictionary.
    ///
    /// - Parameters:
    ///    - titles: The titles for each section, keyed by the `SectionIdentifierType` for the
    ///    section. Any sections that aren't present in the dictionary will have no title.
    ///
    /// - Returns: The data source, to allow continued configuration.
    ///
    public func titled(_ titles: [SectionIdentifierType: String]) -> Self {
        self.sectionTitle = { _, _, section in titles[section] }
        return self
    }

    /// Closure type for determining whether a row in the table can be edited.
    ///
    /// - Parameters:
    ///    - tableView: The table view the row is displayed in.
    ///    - indexPath: The index path of the row in the table view.
    ///    - item: The data source item for the row.
    ///
    /// - Returns: True if the row should be allowed to be edited.
    ///
    public typealias CanEditProvider = (
        _ tableView: UITableView,
        _ indexPath: IndexPath,
        _ item: ItemIdentifierType
    ) -> Bool

    /// Closure type for providing the title for a section of the table view.
    ///
    /// - Parameters:
    ///    - tableView: The table view the section is displayed in.
    ///    - index: The index of the section in the table view.
    ///    - section: The data source type for the section.
    ///
    /// - Returns: A string with the title for the section, or `nil` if there should be no title for the section.
    ///
    public typealias SectionTitleProvider = (
        _ tableView: UITableView,
        _ index: Int,
        _ section: SectionIdentifierType
    ) -> String?

    var canEditRow: CanEditProvider = { (_, _, _) in false }

    /// :nodoc:
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let item = itemIdentifier(for: indexPath) else { return false }
        return canEditRow(tableView, indexPath, item)
    }

    var sectionTitle: SectionTitleProvider = { (_, _, _) in nil }

    /// :nodoc:
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
        -> String?
    {
        let sectionIdentifier = snapshot().sectionIdentifiers[section]
        return sectionTitle(tableView, section, sectionIdentifier)
    }
}

extension CombinableTableViewDataSource where ItemIdentifierType: BindableCell {
    /// Create a new data source for a table view using bindable cells.
    ///
    /// If the items in the snapshots conform to `BindableCell`, the closure to configure cells for the data
    /// source can be omitted. Instead, each item will be bound to its cell using the `BindableCell.bind(to:)`
    /// method.
    ///
    /// - Parameters:
    ///    - tableView: The table view the data source will populate.
    ///
    public convenience init(_ tableView: UITableView) {
        self.init(tableView) { cell, item in
            item.bind(to: cell)
        }
    }
}

#endif
