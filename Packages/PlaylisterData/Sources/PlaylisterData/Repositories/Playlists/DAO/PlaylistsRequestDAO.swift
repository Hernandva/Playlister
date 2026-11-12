import Foundation

/// Request handed to the provider services. Internal to PlaylisterData: never exposed to the app.
struct PlaylistsRequestDAO: Sendable, Equatable {
    let provider: MusicProvider
    let recommendationsTerm: String
    let limits: PlaylistsLimits

    init(provider: MusicProvider, recommendationsTerm: String, limits: PlaylistsLimits) {
        self.provider = provider
        self.recommendationsTerm = recommendationsTerm
        self.limits = limits
    }

    init(_ request: some PlaylistsRequestProtocol, limits: PlaylistsLimits) {
        self.init(provider: request.provider, recommendationsTerm: request.recommendationsTerm, limits: limits)
    }
}

/// Limits of a playlists request, set by `PlaylistsRepository.limits`. Internal.
struct PlaylistsLimits: Sendable, Equatable {
    /// Recommended playlists returned at most.
    let recommendations: Int
    /// Catalogue search results read at most while looking for the recommended playlists.
    let recommendationsSearch: Int
    /// Library playlists returned at most, most recently played first.
    let library: Int
}
