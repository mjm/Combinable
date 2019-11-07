import Combine

public extension Publisher {
    /// A variant of sink that keeps the subscription alive until it completes.
    ///
    /// Use this for publishers that are known to complete at some point in the near future when there is no appropriate
    /// place to store the subscription. Using this with a publisher that doesn't complete will cause a memory leak.
    ///
    /// - Parameters:
    ///    - receiveCompletion: The closure to execute on completion.
    ///    - receiveValue: The closure to execute on receipt of a value.
    ///
    func handle(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) {
        var cancellable: AnyCancellable?
        cancellable
            = sink(
                receiveCompletion: { completion in
                    receiveCompletion(completion)
                    cancellable?.cancel()
                }, receiveValue: receiveValue)
    }
}

public extension Publisher where Failure == Never {
    /// A variant of sink that keeps the subscription alive until it completes.
    ///
    /// Use this for publishers that are known to complete at some point in the near future when there is no appropriate
    /// place to store the subscription. Using this with a publisher that doesn't complete will cause a memory leak.
    ///
    /// - Parameters:
    ///    - receiveValue: The closure to execute on receipt of a value.
    ///
    func handle(receiveValue: @escaping (Output) -> Void) {
        handle(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
}
