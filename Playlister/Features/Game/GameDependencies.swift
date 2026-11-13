import Foundation
import PlaylisterData

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    private let provider: MusicProvider
    private let playlist: GameViewData.Playlist
    private let settings: GameViewData.Settings
    private let songRepository: any SongRepositoryProtocol
    private let playerRepository: any PlayerRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlist: The playlist chosen in ProviderStarter, played by the game.
    ///   - settings: The game settings saved in Settings.
    init(
        provider: MusicProvider,
        playlist: GameViewData.Playlist,
        settings: GameViewData.Settings,
        songRepository: any SongRepositoryProtocol = SongRepository(),
        playerRepository: any PlayerRepositoryProtocol = PlayerRepository()
    ) {
        self.provider = provider
        self.playlist = playlist
        self.settings = settings
        self.songRepository = songRepository
        self.playerRepository = playerRepository
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

    func resolvePlayerRepository() -> any PlayerRepositoryProtocol {
        playerRepository
    }

    func resolvePlayGameSongUseCase() -> any PlayGameSongUseCaseProtocol {
        PlayGameSongUseCase(dependencies: self)
    }

    func resolveGamePlaybackTimeUseCase() -> any GamePlaybackTimeUseCaseProtocol {
        GamePlaybackTimeUseCase(dependencies: self)
    }

    func resolveStopGameSongUseCase() -> any StopGameSongUseCaseProtocol {
        StopGameSongUseCase(dependencies: self)
    }

    func resolveFetchGameSongsUseCase() -> any FetchGameSongsUseCaseProtocol {
        FetchGameSongsUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
