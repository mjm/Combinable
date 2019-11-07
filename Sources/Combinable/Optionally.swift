import Combine

public extension Publisher {
    /// Transform the stream into one that produces optional values of the same time.
    ///
    /// This allows you to use a stream that produces non-optional values with a subscriber that is expecting optionals.
    ///
    func optionally() -> AnyPublisher<Self.Output?, Self.Failure> {
        map { o -> Output? in o }.eraseToAnyPublisher()
    }
}
