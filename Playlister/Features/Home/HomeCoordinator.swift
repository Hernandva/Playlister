import SwiftUI

/// Navigation that Home's view model can trigger.
@MainActor
protocol HomeCoordinatorProtocol: AnyObject {
    /// Opens the screen of `provider` once the user signed in with it.
    func openProvider(_ provider: HomeViewModel.Provider)
}

/// Entry point of the Home feature.
/// Builds the view through `HomeDependencies` and resolves the routes to the features opened from it.
@MainActor
final class HomeCoordinator: Coordinator, HomeCoordinatorProtocol {
    /// One case per feature that can be opened from Home.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies = HomeDependencies()) {
        self.dependencies = dependencies
        dependencies.register(coordinator: self)
    }

    func start() -> some View {
        HomeView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func openProvider(_ provider: HomeViewModel.Provider) {
        // The screen of the provider does not exist yet.
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        // @codegen:destinations
        }
    }
}
