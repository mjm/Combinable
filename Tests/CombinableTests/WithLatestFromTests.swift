import Combinable
import XCTest

final class WithLatestFromTests: TestCase {
    func testEmitsForFirstPublisher() {
        let subject = CurrentValueSubject<[(Int, String)], Never>([])

        let a = PassthroughSubject<Int, Never>()
        let b = PassthroughSubject<String, Never>()

        a.withLatestFrom(b).collect().subscribe(subject).store(in: &cancellables)

        b.send("first")
        a.send(1)
        a.send(2)
        b.send("second")
        b.send("third")
        a.send(3)
        a.send(4)

        a.send(completion: .finished)

        let values = subject.value.map { a, b in ["a": String(describing: a), "b": b] }
        XCTAssertEqual(values, [
            ["a": "1", "b": "first"],
            ["a": "2", "b": "first"],
            ["a": "3", "b": "third"],
            ["a": "4", "b": "third"],
        ])
    }

    func testQueuesEventsUntilSecondPublisher() {
        let subject = CurrentValueSubject<[(Int, String)], Never>([])

        let a = PassthroughSubject<Int, Never>()
        let b = PassthroughSubject<String, Never>()

        a.withLatestFrom(b).collect().subscribe(subject).store(in: &cancellables)

        a.send(1)
        a.send(2)
        b.send("first")
        b.send("second")
        b.send("third")
        a.send(3)
        a.send(4)

        a.send(completion: .finished)

        let values = subject.value.map { a, b in ["a": String(describing: a), "b": b] }
        XCTAssertEqual(values, [
            ["a": "1", "b": "first"],
            ["a": "2", "b": "first"],
            ["a": "3", "b": "third"],
            ["a": "4", "b": "third"],
        ])
    }

    func testForwardsErrorsFromFirstPublisher() {
        let a = PassthroughSubject<Int, Error>()
        let b = PassthroughSubject<String, Error>()

        var error: Error?
        var completed = false

        a.withLatestFrom(b).collect().sink(receiveCompletion: { completion in
            if case let .failure(localError) = completion {
                error = localError
            }

            completed = true
        }, receiveValue: { _ in }).store(in: &cancellables)

        a.send(1)
        b.send("first")

        a.send(completion: .failure(TestError()))

        XCTAssert(completed)
        XCTAssertNotNil(error)
    }

    func testForwardsErrorsFromSecondPublisher() {
        let a = PassthroughSubject<Int, Error>()
        let b = PassthroughSubject<String, Error>()

        var error: Error?
        var completed = false

        a.withLatestFrom(b).collect().sink(receiveCompletion: { completion in
            if case let .failure(localError) = completion {
                error = localError
            }

            completed = true
        }, receiveValue: { _ in }).store(in: &cancellables)

        a.send(1)
        b.send("first")

        b.send(completion: .failure(TestError()))

        XCTAssert(completed)
        XCTAssertNotNil(error)
    }

    func testFinishesOnFirstPublisherFinish() {
        let a = PassthroughSubject<Int, Error>()
        let b = PassthroughSubject<String, Error>()

        var error: Error?
        var completed = false

        a.withLatestFrom(b).collect().sink(receiveCompletion: { completion in
            if case let .failure(localError) = completion {
                error = localError
            }

            completed = true
        }, receiveValue: { _ in }).store(in: &cancellables)

        a.send(1)
        b.send("first")

        a.send(completion: .finished)

        XCTAssert(completed)
        XCTAssertNil(error)
    }

    func testDoesNotFinishOnSecondPublisherFinish() {
        let a = PassthroughSubject<Int, Error>()
        let b = PassthroughSubject<String, Error>()

        var error: Error?
        var completed = false
        var value: [(Int, String)]?

        a.withLatestFrom(b).collect().sink(receiveCompletion: { completion in
            if case let .failure(localError) = completion {
                error = localError
            }

            completed = true
        }, receiveValue: { newValue in value = newValue }).store(in: &cancellables)

        a.send(1)
        b.send("first")

        b.send(completion: .finished)
        a.send(2)
        a.send(3)

        a.send(completion: .finished)

        XCTAssert(completed)
        XCTAssertNil(error)

        let values = value!.map { a, b in ["a": String(describing: a), "b": b] }
        XCTAssertEqual(values, [
            ["a": "1", "b": "first"],
            ["a": "2", "b": "first"],
            ["a": "3", "b": "first"],
        ])
    }

    private struct TestError: Error {
    }

    static var allTests = [
        ("testEmitsForFirstPublisher", testEmitsForFirstPublisher),
        ("testQueuesEventsUntilSecondPublisher", testQueuesEventsUntilSecondPublisher),
        ("testForwardsErrorsFromFirstPublisher", testForwardsErrorsFromFirstPublisher),
        ("testForwardsErrorsFromSecondPublisher", testForwardsErrorsFromSecondPublisher),
        ("testFinishesOnFirstPublisherFinish", testFinishesOnFirstPublisherFinish),
        ("testDoesNotFinishOnSecondPublisherFinish", testDoesNotFinishOnSecondPublisherFinish),
    ]
}

