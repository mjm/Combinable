import Combine

public extension Publisher {
    /// Swallow errors, completing the stream immediately.
    func ignoreError() -> Publishers.Catch<Self, Empty<Output, Never>> {
        self.catch { _ in Empty(completeImmediately: true) }
    }
}
