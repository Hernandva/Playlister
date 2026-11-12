import Foundation
import PlaylisterData

protocol PlaylistCustomArtworkUseCaseProtocol: Sendable {
    /// Returns up to four covers of random songs of the playlist, for a playlist that has no
    /// artwork of its own. The view model adds them to the `customArtworks` of its `PlaylistSelectorViewData`.
    func execute(playlistID: String, provider: MusicProvider) async throws -> [URL]
}

/// Request sent to the Song repository: the playlist and how many songs to pick.
struct PlaylistCustomArtworkRequest: SongRequestProtocol {
    let provider: MusicProvider
    let playlistID: String
    let count: Int
}

/// Builds the artwork of a playlist without one from four random songs, through the Song repository public API.
struct PlaylistCustomArtworkUseCase: PlaylistCustomArtworkUseCaseProtocol {
    /// Covers of the 2×2 mosaic.
    private static let coverCount = 4

    private let repository: any SongRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.repository = dependencies.resolveSongRepository()
    }

    func execute(playlistID: String, provider: MusicProvider) async throws -> [URL] {
        let request = PlaylistCustomArtworkRequest(provider: provider, playlistID: playlistID, count: Self.coverCount)
        let response = try await repository.fetchRandomSongs(request)
        return response.songs.map(\.artworkURL)
    }
}
