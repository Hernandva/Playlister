import Foundation

/// Display-ready data of Game. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct GameViewData: Equatable, Sendable {
    /// Data returned by `GameUseCase`. Rename it after what it holds and add one type and one field
    /// per use case, with the properties the view needs.
    struct Content: Equatable, Sendable {}

    /// Result of `GameUseCase`, or `nil` until it loads.
    var content: Content?
}
