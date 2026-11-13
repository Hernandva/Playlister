import Foundation
import PlaylisterData

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    private let provider: MusicProvider
    private let playlist: GameViewData.Playlist

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlist: The playlist chosen in ProviderStarter, played by the game.
    init(provider: MusicProvider, playlist: GameViewData.Playlist) {
        self.provider = provider
        self.playlist = playlist
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// The playlist the game is played with.
    func resolvePlaylist() -> GameViewData.Playlist {
        playlist
    }

    func resolveUseCase() -> any GameUseCaseProtocol {
        GameUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
