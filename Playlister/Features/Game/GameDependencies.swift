import Foundation
import PlaylisterData

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    private let provider: MusicProvider
    private let playlist: GameViewData.Playlist
    private let settings: GameViewData.Settings
    private let songRepository: any SongRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlist: The playlist chosen in ProviderStarter, played by the game.
    ///   - settings: The game settings saved in Settings.
    init(
        provider: MusicProvider,
        playlist: GameViewData.Playlist,
        settings: GameViewData.Settings,
        songRepository: any SongRepositoryProtocol = SongRepository()
    ) {
        self.provider = provider
        self.playlist = playlist
        self.settings = settings
        self.songRepository = songRepository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// The playlist the game is played with.
    func resolvePlaylist() -> GameViewData.Playlist {
        playlist
    }

    /// The game settings the game is played with.
    func resolveSettings() -> GameViewData.Settings {
        settings
    }

    func resolveSongRepository() -> any SongRepositoryProtocol {
        songRepository
    }

    func resolveFetchGameSongsUseCase() -> any FetchGameSongsUseCaseProtocol {
        FetchGameSongsUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
