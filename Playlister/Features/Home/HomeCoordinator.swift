import Networking
import Observation
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
@Observable
final class HomeCoordinator: Coordinator, HomeCoordinatorProtocol {
    /// One case per feature that can be opened from Home.
    enum Route: Hashable {
        /// Home with a session, for the music service the user signed in with.
        case providerStarter(MusicProvider)
        // @codegen:routes
    }

    /// Route pushed by the view model, e.g. after signing in. `nil` while Home is on top.
    var presentedRoute: Route?
    @ObservationIgnored private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies = HomeDependencies()) {
        self.dependencies = dependencies
        dependencies.register(coordinator: self)
    }

    func start() -> some View {
        HomeView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
            .navigationDestination(item: Bindable(self).presentedRoute) { route in
                self.destination(for: route)
            }
    }

    func openProvider(_ provider: HomeViewModel.Provider) {
        presentedRoute = .providerStarter(Self.musicProvider(for: provider))
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        case .providerStarter(let provider):
            return AnyView(ProviderStarterCoordinator(provider: provider).start())
        // @codegen:destinations
        }
    }
}

private extension HomeCoordinator {
    static func musicProvider(for provider: HomeViewModel.Provider) -> MusicProvider {
        switch provider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        }
    }
}
