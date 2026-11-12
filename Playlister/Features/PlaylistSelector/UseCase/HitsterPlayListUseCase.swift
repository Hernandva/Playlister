import Foundation
import PlaylisterData

protocol HitsterPlayListUseCaseProtocol: Sendable {
    /// Returns the recommended «Hitster» playlists that still exist, in the order of `playlistIDs`.
    /// The view model adds them to the `hitster` of its `PlaylistSelectorViewData`.
    func execute() async throws -> [PlaylistSelectorViewData.Playlist]
}

/// Request sent to the Playlists repository: the music service and the playlists to read.
struct HitsterPlaylistsRequest: RecommendedPlaylistsRequestProtocol {
    let provider: MusicProvider
    let playlistIDs: [String]
}

/// «Recommended Hitster»: reads a fixed list of playlists by identifier through the Playlists repository
/// public API, all in one request.
struct HitsterPlayListUseCase: HitsterPlayListUseCaseProtocol {
    /// Apple Music catalogue identifiers of the recommended «Hitster» playlists, in the order they are shown.
    /// It is the last part of the playlist's link, e.g. music.apple.com/es/playlist/hitster/pl.u-DdANxEPFj4Jyvq.
    /// Add more by hand; they are all read in one request.
    private static let playlistIDs = [
        "pl.u-DdANxEPFj4Jyvq"
    ]

    private let provider: MusicProvider
    private let repository: any PlaylistsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> [PlaylistSelectorViewData.Playlist] {
        let request = HitsterPlaylistsRequest(provider: provider, playlistIDs: Self.playlistIDs)
        let response = try await repository.fetchRecommended(request)
        return response.playlists.map(PlaylistItemMapper.playlist(from:))
    }
}
