import SwiftUI

/// Entry point of the PlaylistSelector feature.
/// Builds the view through `PlaylistSelectorDependencies` and resolves the routes to the features opened from it.
@MainActor
final class PlaylistSelectorCoordinator: Coordinator {
    /// One case per feature that can be opened from PlaylistSelector.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: PlaylistSelectorDependencies

    init(dependencies: PlaylistSelectorDependencies = PlaylistSelectorDependencies()) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        PlaylistSelectorView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        // @codegen:destinations
        }
    }
}
