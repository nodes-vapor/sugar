import Vapor

public extension Future {
    func `try`(_ callback: @escaping (Expectation) throws -> Void) -> Future<T> {
        return map {
            try callback($0)
            return $0
        }
    }

    func flatTry(_ callback: @escaping (Expectation) throws -> Future<Void>) -> Future<T> {
        return flatMap { expectation in
            try callback(expectation).map { _ in expectation }
        }
    }
}

public extension Future where Expectation: OptionalType {
    func `nil`(or error: @autoclosure @escaping () -> Error) -> Future<Void> {
        return map(to: Void.self) { optional in
            guard optional.wrapped == nil else {
                throw error()
            }
        }
    }
}

public extension Future where Expectation: Equatable {
    func equal(
        _ expected: Expectation,
        or error: @autoclosure @escaping () -> Error
    ) -> Future<Void> {
        return map(to: Void.self) { value in
            guard value == expected else {
                throw error()
            }
        }
    }
}

public func syncFlatten<T>(futures: [LazyFuture<T>], on worker: Worker) -> Future<[T]> {
    let promise = worker.eventLoop.newPromise([T].self)

    var results: [T] = []

    var iterator = futures.makeIterator()
    func handle(_ future: LazyFuture<T>) {
        do {
            try future().do { res in
                results.append(res)
                if let next = iterator.next() {
                    handle(next)
                } else {
                    promise.succeed(result: results)
                }
                }.catch { error in
                    promise.fail(error: error)
            }
        } catch {
            promise.fail(error: error)
        }
    }

    if let first = iterator.next() {
        handle(first)
    } else {
        promise.succeed(result: results)
    }

    return promise.futureResult
}
