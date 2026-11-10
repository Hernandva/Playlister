import SwiftUI

/// Contract shared by every feature coordinator.
///
/// A coordinator is the only entry point of its feature: it builds the feature's view
/// through the feature's dependency container (`start()`) and resolves the routes to the
/// features that can be opened from it (`destination(for:)`).
@MainActor
protocol Coordinator: AnyObject {
    associatedtype Route: Hashable
    associatedtype Content: View

    /// Builds the feature's root view with all of its dependencies injected.
    func start() -> Content

    /// Returns the view of the child feature that a route points to.
    func destination(for route: Route) -> AnyView
}
