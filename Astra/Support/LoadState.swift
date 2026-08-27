import Foundation

/// One value describing everything a screen can be doing.
///
/// Views `switch` over this, and because a `switch` has to be exhaustive, no
/// screen can quietly forget to handle loading or failure.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(NetworkError)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}
