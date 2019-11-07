import Combine

public extension Publisher where Output == Bool {
    /// Inverts boolean values in the stream.
    func invert() -> AnyPublisher<Self.Output, Self.Failure> {
        map { !$0 }.eraseToAnyPublisher()
    }
}
