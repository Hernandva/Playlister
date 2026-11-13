import Foundation

/// Request handed to the provider services. Internal to PlaylisterData: never exposed to the app.
struct SongRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let playlistID: String
    let count: Int

    init(provider: MusicProvider, playlistID: String, count: Int) {
        self.provider = provider
        self.playlistID = playlistID
        self.count = count
    }

    init(_ request: some SongRequestProtocol) {
        self.init(provider: request.provider, playlistID: request.playlistID, count: request.count)
    }
}

/// Request of one page of the songs of a playlist, handed to the provider services. Internal.
struct PlaylistSongsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let playlistID: String
    let offset: Int
    /// Songs per page, set by `SongRepository.songsPageSize`.
    let limit: Int

    init(provider: MusicProvider, playlistID: String, offset: Int, limit: Int) {
        self.provider = provider
        self.playlistID = playlistID
        self.offset = offset
        self.limit = limit
    }

    init(_ request: some PlaylistSongsRequestProtocol, limit: Int) {
        self.init(provider: request.provider, playlistID: request.playlistID, offset: request.offset, limit: limit)
    }
}
