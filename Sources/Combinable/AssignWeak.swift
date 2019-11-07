import Combine

public extension Publisher where Failure == Never {
    /// Assign the output to a property of an object.
    ///
    /// - Parameters:
    ///    - keyPath: A key path indicating the property to assign.
    ///    - object: The object that contains the property.
    ///    - weak: Whether to hold `object` weakly or not. Use this to avoid cycles.
    ///
    /// - Returns:A subscriber that assigns the value to the property.
    ///
    func assign<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on object: Root,
        weak: Bool
    ) -> AnyCancellable {
        // TODO maybe implement this as a real subscriber
        if weak {
            return sink { [weak object] newValue in
                object?[keyPath: keyPath] = newValue
            }
        } else {
            return assign(to: keyPath, on: object)
        }
    }
}
