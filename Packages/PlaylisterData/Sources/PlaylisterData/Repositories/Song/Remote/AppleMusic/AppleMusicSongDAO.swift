import Foundation

/// Attributes of a `songs` or `library-songs` resource of the Apple Music API. Internal.
struct AppleMusicSongAttributesDAO: Decodable, Sendable {
    let name: String
    let artistName: String
    /// Missing for songs without artwork, e.g. some songs the user uploaded.
    let artwork: AppleMusicArtworkDAO?
}

extension SongItemDAO {
    /// A song of the Apple Music API, or `nil` when it has no attributes or no web artwork.
    init?(song resource: AppleMusicResourceDAO<AppleMusicSongAttributesDAO>, artworkSide: Int) {
        guard let attributes = resource.attributes,
              let artworkURL = attributes.artwork?.url(side: artworkSide) else { return nil }
        self.init(id: resource.id, title: attributes.name, artistName: attributes.artistName, artworkURL: artworkURL)
    }
}
