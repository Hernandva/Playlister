import PlaylisterData
import SwiftUI

/// Entry point of the ProviderStarter feature: Home with a session, opened once the user signed in.
/// Builds the view through `ProviderStarterDependencies` and resolves the routes to the features opened from it.
@MainActor
final class ProviderStarterCoordinator: Coordinator {
    /// One case per feature that can be opened from ProviderStarter.
    enum Route: Hashable {
        /// Playback, game mode, Bingo categories and account.
        case settings
        /// Recommended and own playlists, to choose the one to play.
        case playlistSelector
        case game
        // @codegen:routes
    }

    private let dependencies: ProviderStarterDependencies

    init(dependencies: ProviderStarterDependencies) {
        self.dependencies = dependencies
    }

    /// - Parameters:
    ///   - provider: The music service the user signed in with in Home.
    ///   - signOut: Goes back to Home.
    convenience init(provider: MusicProvider, signOut: @escaping @MainActor () -> Void) {
        self.init(dependencies: ProviderStarterDependencies(provider: provider, signOut: signOut))
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
            return AnyView(SettingsCoordinator(
                provider: dependencies.resolveProvider(),
                signOut: dependencies.resolveSignOut()
            ).start())
        case .playlistSelector:
            let selectPlaylist = dependencies.resolveSelectPlaylist()
            return AnyView(PlaylistSelectorCoordinator(provider: dependencies.resolveProvider()) { playlist in
                // The selector does not read the songs, so the count is unknown until the game loads them.
                selectPlaylist(ProviderStarterViewData.Playlist(
                    id: playlist.id,
                    name: playlist.name,
                    songCount: nil,
                    covers: playlist.covers
                ))
            }.start())
        case .game:
            return AnyView(GameCoordinator().start())
        // @codegen:destinations
        }
    }
}
