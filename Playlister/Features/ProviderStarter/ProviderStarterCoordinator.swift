import Networking
import SwiftUI

/// Entry point of the ProviderStarter feature: Home with a session, opened once the user signed in.
/// Builds the view through `ProviderStarterDependencies` and resolves the routes to the features opened from it.
@MainActor
final class ProviderStarterCoordinator: Coordinator {
    /// One case per feature that can be opened from ProviderStarter.
    enum Route: Hashable {
        case settings
        // @codegen:routes
    }

    private let dependencies: ProviderStarterDependencies

    init(dependencies: ProviderStarterDependencies) {
        self.dependencies = dependencies
    }

    /// - Parameter provider: The music service the user signed in with in Home.
    convenience init(provider: MusicProvider) {
        self.init(dependencies: ProviderStarterDependencies(provider: provider))
    }

    func start() -> some View {
        ProviderStarterView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        case .settings:
            return AnyView(SettingsCoordinator().start())
        // @codegen:destinations
        }
    }
}
