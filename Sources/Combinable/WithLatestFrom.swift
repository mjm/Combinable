import Combine

public extension Publisher {
    /// Publishes the values from this publisher combined with whatever the latest value
    /// from `other` was at the time.
    ///
    /// The publisher will complete when either upstream publisher fails, or when this
    /// publisher finishes successfully. If `other` finishes successfully, the returned
    /// publisher will continue using that most recent value from `other` for new events.
    ///
    /// - Parameters:
    ///    - other: Another publisher whose latest values should accompany events
    ///    from this publisher.
    ///
    /// - Returns: A new publisher of pairs of values from `self` and `other`.
    ///
    func withLatestFrom<P: Publisher>(
        _ other: P
    ) -> WithLatestFrom<Self, P> where Failure == P.Failure {
        WithLatestFrom(self, other)
    }
}

/// A publisher that combines values from one publisher with the latest value from another.
public struct WithLatestFrom<A: Publisher, B: Publisher>: Publisher where A.Failure == B.Failure {
    public typealias Output = (A.Output, B.Output)
    public typealias Failure = A.Failure

    let a: A
    let b: B

    public init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        a.subscribe(Inner(downstream: subscriber, b: b))
    }

    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription
    where Downstream.Input == Output, Downstream.Failure == Failure {
        typealias Input = A.Output
        typealias Failure = A.Failure

        let downstream: Downstream
        let b: B

        var upstreamSubscription: Subscription?

        var latestSubscription: AnyCancellable?
        var latestValue: B.Output?

        var queued: [A.Output] = []

        init(downstream: Downstream, b: B) {
            self.downstream = downstream
            self.b = b
        }

        func receive(subscription: Subscription) {
            upstreamSubscription = subscription

            latestSubscription
                = b.sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure = completion {
                            self?.receive(completion: completion)
                        }
                    },
                    receiveValue: { [weak self] value in
                        guard let self = self else { return }

                        self.latestValue = value
                        self.sendQueued()
                    })

            downstream.receive(subscription: self)
        }

        func receive(_ input: A.Output) -> Subscribers.Demand {
            guard let latest = latestValue else {
                queued.append(input)
                return .none
            }

            return downstream.receive((input, latest))
        }

        func receive(completion: Subscribers.Completion<A.Failure>) {
            downstream.receive(completion: completion)
            cancel()
        }

        func request(_ demand: Subscribers.Demand) {
            upstreamSubscription?.request(demand)
        }

        func cancel() {
            upstreamSubscription?.cancel()
            latestSubscription?.cancel()
        }

        private func sendQueued() {
            guard !queued.isEmpty else { return }

            var newDemand: Subscribers.Demand = .none
            for item in queued {
                newDemand += downstream.receive((item, latestValue!))
            }

            queued.removeAll()
        }
    }
}
