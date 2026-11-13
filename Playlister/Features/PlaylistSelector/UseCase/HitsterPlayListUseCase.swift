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
        "pl.u-8aAVXd6Cvrrbmz0",
        "pl.u-b3b8M68CKqG0PpY",
        "pl.u-DdANxEPFj4Jyvq",
        "pl.u-leyll9Ltj6b7KpW",
        "pl.u-NpXmYAau8EMRA",
        "pl.u-vxy665jskD2JG3",
        "pl.u-V9D7m8pC3r3gRYg",
        "pl.u-V9D7m8pC3r3gRYg",
        "pl.u-EdAVvbbFJMjMEA",
        "pl.u-gxbllD0IWAVN9d"
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
