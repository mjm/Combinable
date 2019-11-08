import Combinable

// NSDiffableDataSourceSnapshot exists in one of these two frameworks
#if canImport(AppKit)
#if targetEnvironment(macCatalyst)
import UIKit
#else
import AppKit
#endif
#elseif canImport(UIKit)
import UIKit
#endif

@available(OSX 10.15.1, *)
public protocol DiffableSnapshotApplying: class {
    associatedtype SectionIdentifierType: Hashable
    associatedtype ItemIdentifierType: Hashable

    var cancellables: Set<AnyCancellable> { get set }

    func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool, completion: (() -> Void)?
    )
}

@available(OSX 10.15.1, *)
extension DiffableSnapshotApplying {
    public typealias SnapshotType = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>

    public func bound<Snapshot: Publisher, Animate: Publisher>(
        to snapshot: Snapshot,
        animate: Animate
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never,
        Animate.Output == Bool,
        Animate.Failure == Never
    {
        snapshot.withLatestFrom(animate)
            .sink { [weak self] input in
                let (snapshot, animate) = input
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }

    public func bound<Snapshot: Publisher>(
        to snapshot: Snapshot,
        animate: Bool
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never
    {
        snapshot
            .sink { [weak self] snapshot in
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }

    public func bound<Snapshot: Publisher, Animate: Publisher, Schedule: Scheduler>(
        to snapshot: Snapshot,
        animate: Animate,
        on scheduler: Schedule
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never,
        Animate.Output == Bool,
        Animate.Failure == Never
    {
        snapshot.withLatestFrom(animate)
            .receive(on: scheduler)
            .sink { [weak self] input in
                let (snapshot, animate) = input
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }
}
