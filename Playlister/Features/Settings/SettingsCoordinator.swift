import PlaylisterData
import SwiftUI

/// Entry point of the Settings feature: playback, game mode, Bingo level and categories, and account.
/// Builds the view through `SettingsDependencies` and resolves the routes to the features opened from it.
@MainActor
final class SettingsCoordinator: Coordinator {
    /// One case per feature that can be opened from Settings.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: SettingsDependencies

    init(dependencies: SettingsDependencies) {
        self.dependencies = dependencies
    }

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - signOut: Goes back to Home.
    convenience init(provider: MusicProvider, signOut: @escaping @MainActor () -> Void) {
        self.init(dependencies: SettingsDependencies(provider: provider, signOut: signOut))
    }

    func start() -> some View {
        SettingsView(dependencies: dependencies)
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
