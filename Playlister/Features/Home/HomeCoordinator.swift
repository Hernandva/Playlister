import SwiftUI

/// Entry point of the Home feature.
/// Builds the view through `HomeDependencies` and resolves the routes to the features opened from it.
@MainActor
final class HomeCoordinator: Coordinator {
    /// One case per feature that can be opened from Home.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies = HomeDependencies()) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        HomeView(viewModel: dependencies.makeViewModel())
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
