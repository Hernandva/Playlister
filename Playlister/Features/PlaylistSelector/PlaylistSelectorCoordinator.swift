import PlaylisterData
import SwiftUI

/// Entry point of the PlaylistSelector feature: the recommended and the user's playlists, to choose the one to play.
/// Builds the view through `PlaylistSelectorDependencies` and resolves the routes to the features opened from it.
@MainActor
final class PlaylistSelectorCoordinator: Coordinator {
    /// One case per feature that can be opened from PlaylistSelector.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: PlaylistSelectorDependencies

    init(dependencies: PlaylistSelectorDependencies) {
        self.dependencies = dependencies
    }

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - selectPlaylist: Receives the playlist the user confirmed; the selector then closes.
    convenience init(
        provider: MusicProvider,
        selectPlaylist: @escaping @MainActor (PlaylistSelectorViewData.Playlist) -> Void
    ) {
        self.init(dependencies: PlaylistSelectorDependencies(provider: provider, selectPlaylist: selectPlaylist))
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
