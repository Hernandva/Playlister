import Foundation

/// Attributes of a `playlists` (catalogue) or `library-playlists` resource of the Apple Music API. Internal.
struct AppleMusicPlaylistAttributesDAO: Decodable, Sendable {
    let name: String
    /// Who made a catalogue playlist. Library playlists are the user's own and have none.
    let curatorName: String?
    /// Missing for playlists without artwork of their own.
    let artwork: AppleMusicArtworkDAO?
}

/// Response of `GET /v1/catalog/{storefront}/search`: `{ "results": { "playlists": { page } } }`. Internal.
struct AppleMusicPlaylistsSearchDAO: Decodable, Sendable {
    struct Results: Decodable, Sendable {
        /// Missing when the search found no playlists.
        let playlists: AppleMusicPageDAO<AppleMusicPlaylistAttributesDAO>?
    }

    let results: Results
}

extension PlaylistsItemDAO {
    /// A playlist of the Apple Music API, or `nil` when the API left out its attributes.
    init?(playlist resource: AppleMusicResourceDAO<AppleMusicPlaylistAttributesDAO>, artworkSide: Int) {
        guard let attributes = resource.attributes else { return nil }
        self.init(
            id: resource.id,
            name: attributes.name,
            curatorName: attributes.curatorName,
            artworkURL: attributes.artwork?.url(side: artworkSide)
        )
    }
}
