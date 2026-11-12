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
