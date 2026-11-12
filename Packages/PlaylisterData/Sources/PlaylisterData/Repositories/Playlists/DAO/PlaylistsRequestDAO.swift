import Foundation

/// Request of the library playlists. Internal to PlaylisterData: never exposed to the app.
struct LibraryPlaylistsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    /// Playlists returned at most, set by `PlaylistsRepository.libraryLimit`.
    let limit: Int

    init(provider: MusicProvider, limit: Int) {
        self.provider = provider
        self.limit = limit
    }

    init(_ request: some LibraryPlaylistsRequestProtocol, limit: Int) {
        self.init(provider: request.provider, limit: limit)
    }
}

/// Request of the recommended playlists. Internal to PlaylisterData: never exposed to the app.
struct RecommendedPlaylistsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let playlistIDs: [String]

    init(provider: MusicProvider, playlistIDs: [String]) {
        self.provider = provider
        self.playlistIDs = playlistIDs
    }

    init(_ request: some RecommendedPlaylistsRequestProtocol) {
        self.init(provider: request.provider, playlistIDs: request.playlistIDs)
    }
}

/// Request of one search page. Internal to PlaylisterData: never exposed to the app.
struct PlaylistsSearchRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let term: String
    let offset: Int
    /// Playlists per page, set by `PlaylistsRepository.searchPageSize`.
    let limit: Int

    init(provider: MusicProvider, term: String, offset: Int, limit: Int) {
        self.provider = provider
        self.term = term
        self.offset = offset
        self.limit = limit
    }

    init(_ request: some PlaylistsSearchRequestProtocol, limit: Int) {
        self.init(provider: request.provider, term: request.term, offset: request.offset, limit: limit)
    }
}
