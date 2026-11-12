import Foundation

/// Playlists of a music service. Internal to PlaylisterData: the app only sees PlaylistsResponseProtocol.
struct PlaylistsResponseDAO: Sendable, Equatable, PlaylistsResponseProtocol {
    let provider: MusicProvider
    let items: [PlaylistsItemDAO]

    var playlists: [any PlaylistsItemProtocol] { items }
}

/// One page of a search. Internal to PlaylisterData: the app only sees PlaylistsSearchResponseProtocol.
struct PlaylistsSearchResponseDAO: Sendable, Equatable, PlaylistsSearchResponseProtocol {
    let provider: MusicProvider
    let items: [PlaylistsItemDAO]
    let hasMore: Bool

    var playlists: [any PlaylistsItemProtocol] { items }
}

/// A playlist of a music service. Internal: the app only sees PlaylistsItemProtocol.
struct PlaylistsItemDAO: Sendable, Equatable, PlaylistsItemProtocol {
    let id: String
    let name: String
    let curatorName: String?
    let artworkURL: URL?
}
