import Foundation
import PlaylisterData

protocol FetchSongsFromPlaylistUseCaseProtocol: Sendable {
    /// Returns one page of the songs of the playlist, in their order, starting at `offset`.
    /// The view model adds it to the `playlistSongs` of its `PlaylistSelectorViewData`.
    func execute(playlistID: String, provider: MusicProvider, offset: Int) async throws
        -> PlaylistSelectorViewData.SongsPage
}

/// Request sent to the Song repository: the playlist and where the page starts.
struct FetchSongsFromPlaylistRequest: PlaylistSongsRequestProtocol {
    let provider: MusicProvider
    let playlistID: String
    let offset: Int
}

/// Songs of the long-press sheet: lists the songs of a playlist, 25 at a time, through the Song repository public API.
struct FetchSongsFromPlaylistUseCase: FetchSongsFromPlaylistUseCaseProtocol {
    private let repository: any SongRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.repository = dependencies.resolveSongRepository()
    }

    func execute(playlistID: String, provider: MusicProvider, offset: Int) async throws
        -> PlaylistSelectorViewData.SongsPage {
        let request = FetchSongsFromPlaylistRequest(provider: provider, playlistID: playlistID, offset: offset)
        let response: any PlaylistSongsResponseProtocol
        do {
            response = try await repository.fetchSongs(request)
        } catch SongError.playlistNotFound where offset == 0 {
            // The Apple Music API answers 404 for the songs of an empty library playlist.
            return PlaylistSelectorViewData.SongsPage(songs: [], nextOffset: 0, hasMore: false, total: 0)
        }
        return PlaylistSelectorViewData.SongsPage(
            songs: response.songs.map { song in
                PlaylistSelectorViewData.Song(
                    id: song.id,
                    title: song.title,
                    artist: song.artistName,
                    cover: song.artworkURL,
                    duration: song.duration
                )
            },
            nextOffset: offset + response.songs.count,
            hasMore: response.hasMore,
            total: response.total
        )
    }
}
