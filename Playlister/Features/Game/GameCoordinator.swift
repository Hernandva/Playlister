import PlaylisterData
import SwiftUI

/// Entry point of the Game feature.
/// Builds the view through `GameDependencies` and resolves the routes to the features opened from it.
@MainActor
final class GameCoordinator: Coordinator {
    /// One case per feature that can be opened from Game.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: GameDependencies

    init(dependencies: GameDependencies) {
        self.dependencies = dependencies
    }

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlist: The playlist chosen in GameStarter, played by the game.
    ///   - settings: The game settings saved in Settings.
    convenience init(provider: MusicProvider, playlist: GameViewData.Playlist, settings: GameViewData.Settings) {
        self.init(dependencies: GameDependencies(provider: provider, playlist: playlist, settings: settings))
    }

    func start() -> some View {
        GameView(dependencies: dependencies)
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
