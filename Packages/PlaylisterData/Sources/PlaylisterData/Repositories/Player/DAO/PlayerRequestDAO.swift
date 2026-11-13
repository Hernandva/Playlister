import Foundation

/// Request handed to the provider players. Internal to PlaylisterData: never exposed to the app.
struct PlayerRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let songID: String
    let startTime: TimeInterval

    init(provider: MusicProvider, songID: String, startTime: TimeInterval) {
        self.provider = provider
        self.songID = songID
        self.startTime = startTime
    }

    init(_ request: some PlayerRequestProtocol) {
        self.init(provider: request.provider, songID: request.songID, startTime: request.startTime)
    }
}
