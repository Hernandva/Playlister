import Foundation

/// Attributes of a `library-playlists` resource of the Apple Music API. Internal.
struct AppleMusicLibraryPlaylistAttributesDAO: Decodable, Sendable {
    let name: String
    /// Missing for playlists without artwork of their own.
    let artwork: AppleMusicArtworkDAO?
}

extension PlaylistsItemDAO {
    /// A library playlist of the Apple Music API, or `nil` when the API left out its attributes.
    /// Library playlists are the user's own, so they have no curator.
    init?(libraryPlaylist resource: AppleMusicResourceDAO<AppleMusicLibraryPlaylistAttributesDAO>, artworkSide: Int) {
        guard let attributes = resource.attributes else { return nil }
        self.init(
            id: resource.id,
            name: attributes.name,
            curatorName: nil,
            artworkURL: attributes.artwork?.url(side: artworkSide)
        )
    }
}
