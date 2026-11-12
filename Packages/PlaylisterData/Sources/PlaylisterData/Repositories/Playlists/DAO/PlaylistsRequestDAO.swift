import Foundation

/// Request handed to the provider services. Internal to PlaylisterData: never exposed to the app.
struct PlaylistsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let recommendedPlaylistIDs: [String]
    /// Library playlists returned at most, set by `PlaylistsRepository.libraryLimit`.
    let libraryLimit: Int

    init(provider: MusicProvider, recommendedPlaylistIDs: [String], libraryLimit: Int) {
        self.provider = provider
        self.recommendedPlaylistIDs = recommendedPlaylistIDs
        self.libraryLimit = libraryLimit
    }

    init(_ request: some PlaylistsRequestProtocol, libraryLimit: Int) {
        self.init(
            provider: request.provider,
            recommendedPlaylistIDs: request.recommendedPlaylistIDs,
            libraryLimit: libraryLimit
        )
    }
}
