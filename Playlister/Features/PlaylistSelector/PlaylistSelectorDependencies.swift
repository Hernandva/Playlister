import Foundation
import PlaylisterData

/// Dependency injection container of PlaylistSelector: the only place where its concrete types are built.
@MainActor
final class PlaylistSelectorDependencies {
    private let provider: MusicProvider
    private let selectPlaylist: @MainActor (PlaylistSelectorViewData.Playlist) -> Void
    private let repository: any PlaylistsRepositoryProtocol
    private let songRepository: any SongRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - selectPlaylist: Hands the playlist the user confirmed back to the feature that opened the selector.
    init(
        provider: MusicProvider,
        selectPlaylist: @escaping @MainActor (PlaylistSelectorViewData.Playlist) -> Void,
        repository: any PlaylistsRepositoryProtocol = PlaylistsRepository(),
        songRepository: any SongRepositoryProtocol = SongRepository()
    ) {
        self.provider = provider
        self.selectPlaylist = selectPlaylist
        self.repository = repository
        self.songRepository = songRepository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// Action of «Select playlist» in the confirmation sheet.
    func resolveSelectPlaylist() -> @MainActor (PlaylistSelectorViewData.Playlist) -> Void {
        selectPlaylist
    }

    func resolveRepository() -> any PlaylistsRepositoryProtocol {
        repository
    }

    /// Random songs of a playlist, for the artwork of playlists without one.
    func resolveSongRepository() -> any SongRepositoryProtocol {
        songRepository
    }

    func resolveMyPlaylistUseCase() -> any MyPlaylistUseCaseProtocol {
        MyPlaylistUseCase(dependencies: self)
    }

    func resolveHitsterPlayListUseCase() -> any HitsterPlayListUseCaseProtocol {
        HitsterPlayListUseCase(dependencies: self)
    }

    func resolveSearchByTermUseCase() -> any SearchByTermUseCaseProtocol {
        SearchByTermUseCase(dependencies: self)
    }

    func resolvePlaylistCustomArtworkUseCase() -> any PlaylistCustomArtworkUseCaseProtocol {
        PlaylistCustomArtworkUseCase(dependencies: self)
    }

    func resolveViewModel() -> PlaylistSelectorViewModel {
        PlaylistSelectorViewModel(dependencies: self)
    }
}
