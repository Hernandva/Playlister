import PlaylisterData
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
        case gameStarter(MusicProvider)
        // @codegen:routes
    }

    /// Screens on the navigation stack above Home. `RootView` binds the stack to it, so the routes that
    /// `NavigationLink(value:)` pushes from any feature are appended here too.
    var path = NavigationPath()
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
    }

    func openProvider(_ provider: HomeViewModel.Provider) {
        path.append(Route.gameStarter(Self.musicProvider(for: provider)))
    }

    /// Pops every screen opened after signing in, back to Home.
    func signOut() {
        path = NavigationPath()
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        case .gameStarter(let provider):
            return AnyView(GameStarterCoordinator(
                provider: provider,
                signOut: { [weak self] in
                    self?.signOut()
                },
                navigate: { [weak self] route in
                    self?.path.append(route)
                }
            ).start())
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
