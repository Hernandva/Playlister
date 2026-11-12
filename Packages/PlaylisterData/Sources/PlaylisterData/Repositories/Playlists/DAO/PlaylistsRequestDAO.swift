import Foundation

/// Request handed to the provider services. Internal to PlaylisterData: never exposed to the app.
struct PlaylistsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let recommendationsTerm: String

    init(provider: MusicProvider, recommendationsTerm: String) {
        self.provider = provider
        self.recommendationsTerm = recommendationsTerm
    }

    init(_ request: some PlaylistsRequestProtocol) {
        self.init(provider: request.provider, recommendationsTerm: request.recommendationsTerm)
    }
}
