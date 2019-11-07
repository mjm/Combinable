import Combine
import CoreData

public extension NSManagedObjectContext {
    func changesPublisher<Object: NSManagedObject>(for fetchRequest: NSFetchRequest<Object>)
        -> ManagedObjectChangesPublisher<Object>
    {
        ManagedObjectChangesPublisher(fetchRequest: fetchRequest, context: self)
    }
}

public struct ManagedObjectChangesPublisher<Object: NSManagedObject>: Publisher {
    public typealias Output = CollectionDifference<Object>
    public typealias Failure = Error

    let fetchRequest: NSFetchRequest<Object>
    let context: NSManagedObjectContext

    public init(fetchRequest: NSFetchRequest<Object>, context: NSManagedObjectContext) {
        self.fetchRequest = fetchRequest
        self.context = context
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let inner = Inner(downstream: subscriber, fetchRequest: fetchRequest, context: context)
        subscriber.receive(subscription: inner)
    }

    private final class Inner<Downstream: Subscriber>: NSObject, Subscription,
        NSFetchedResultsControllerDelegate
    where Downstream.Input == CollectionDifference<Object>, Downstream.Failure == Error {
        private let downstream: Downstream
        private var fetchedResultsController: NSFetchedResultsController<Object>?

        init(
            downstream: Downstream,
            fetchRequest: NSFetchRequest<Object>,
            context: NSManagedObjectContext
        ) {
            self.downstream = downstream
            fetchedResultsController
                = NSFetchedResultsController(
                    fetchRequest: fetchRequest,
                    managedObjectContext: context,
                    sectionNameKeyPath: nil,
                    cacheName: nil)

            super.init()

            fetchedResultsController!.delegate = self

            do {
                try fetchedResultsController!.performFetch()
                updateDiff()
            } catch {
                downstream.receive(completion: .failure(error))
            }
        }

        private var demand: Subscribers.Demand = .none

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private var lastSentState: [Object] = []
        private var currentDifferences = CollectionDifference<Object>([])!

        private func updateDiff() {
            currentDifferences
                = Array(fetchedResultsController?.fetchedObjects ?? []).difference(
                    from: lastSentState)
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 && !currentDifferences.isEmpty {
                let newDemand = downstream.receive(currentDifferences)
                lastSentState = Array(fetchedResultsController?.fetchedObjects ?? [])
                currentDifferences = lastSentState.difference(from: lastSentState)

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        }

        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            updateDiff()
        }

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}

