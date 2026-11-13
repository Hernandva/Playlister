import Foundation

/// Attributes of a `songs` or `library-songs` resource of the Apple Music API. Internal.
struct AppleMusicSongAttributesDAO: Decodable, Sendable {
    let name: String
    let artistName: String
    /// Missing for songs without artwork, e.g. some songs the user uploaded.
    let artwork: AppleMusicArtworkDAO?
    /// Length of the song, when the API gives it.
    let durationInMillis: Int?
}

extension SongItemDAO {
    /// A song of the Apple Music API, or `nil` when it has no attributes or no web artwork.
    init?(song resource: AppleMusicResourceDAO<AppleMusicSongAttributesDAO>, artworkSide: Int) {
        guard let attributes = resource.attributes,
              let artworkURL = attributes.artwork?.url(side: artworkSide) else { return nil }
        self.init(id: resource.id, title: attributes.name, artistName: attributes.artistName, artworkURL: artworkURL)
    }
}

extension PlaylistSongItemDAO {
    private static let millisecondsPerSecond: TimeInterval = 1000

    /// A song of the Apple Music API, with or without artwork, or `nil` when it has no attributes.
    init?(song resource: AppleMusicResourceDAO<AppleMusicSongAttributesDAO>, artworkSide: Int) {
        guard let attributes = resource.attributes else { return nil }
        self.init(
            id: resource.id,
            title: attributes.name,
            artistName: attributes.artistName,
            artworkURL: attributes.artwork?.url(side: artworkSide),
            duration: attributes.durationInMillis.map { TimeInterval($0) / Self.millisecondsPerSecond }
        )
    }
}
