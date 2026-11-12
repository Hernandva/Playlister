import Foundation

/// Playlists of a music service. Internal to PlaylisterData: the app only sees PlaylistsResponseProtocol.
struct PlaylistsResponseDAO: Sendable, Equatable, PlaylistsResponseProtocol {
    let provider: MusicProvider
    let recommendedItems: [PlaylistsItemDAO]
    let libraryItems: [PlaylistsItemDAO]

    var recommended: [any PlaylistsItemProtocol] { recommendedItems }
    var library: [any PlaylistsItemProtocol] { libraryItems }
}

/// A playlist of a music service. Internal: the app only sees PlaylistsItemProtocol.
struct PlaylistsItemDAO: Sendable, Equatable, PlaylistsItemProtocol {
    let id: String
    let name: String
    let curatorName: String?
    let artworkURL: URL?
}
