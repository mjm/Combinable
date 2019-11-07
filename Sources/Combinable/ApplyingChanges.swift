import Combine

public extension Publisher {
    /// Modifies the collections in the output by applying lists of changes from another publisher.
    ///
    /// This is most useful when the publisher feeds this result back into itself, so that the next element in the stream
    /// is the result of applying the last collection of changes.
    ///
    /// Use the `transform` closure to produce a collection of elements parallel to the elements in the collection
    /// producing the changes. The benefit of doing this instead of just mapping over the collection is that you only
    /// create new elements when they were inserted in the original list: otherwise, the value remains the same.
    ///
    /// - Parameters:
    ///    - changes: A publisher that emits collections of changes that should be applied to the collections
    ///      that this publisher produces. The type of element for the changes can be different than the elements
    ///      in those collections.
    ///    - transform: A closure that is called on each inserted element found in `changes` that transforms
    ///      it into the element that will inserted into the collections emitted by the returned publisher.
    ///
    /// - Returns: A new publisher that emits the collections from this publisher with the changes applied.
    ///
    func applyingChanges<Changes: Publisher, ChangeItem>(
        _ changes: Changes,
        _ transform: @escaping (ChangeItem) -> Output.Element
    ) -> AnyPublisher<Output, Failure>
    where Output: RangeReplaceableCollection,
        Output.Index == Int,
        Changes.Output == CollectionDifference<ChangeItem>,
        Changes.Failure == Failure
    {
        zip(changes) { existing, changes -> Output in
            var objects = existing
            for change in changes {
                switch change {
                case .remove(let offset, _, _):
                    objects.remove(at: offset)
                case .insert(let offset, let obj, _):
                    let transformed = transform(obj)
                    objects.insert(transformed, at: offset)
                }
            }
            return objects
        }.eraseToAnyPublisher()
    }
}
