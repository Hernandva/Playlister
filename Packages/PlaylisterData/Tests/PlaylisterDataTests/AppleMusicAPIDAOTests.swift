@testable import PlaylisterData
import Foundation
import Testing

struct AppleMusicAPIDAOTests {
    private static func decode<Attributes>(
        _ json: String,
        as type: Attributes.Type
    ) throws -> AppleMusicPageDAO<Attributes> {
        try JSONDecoder().decode(AppleMusicPageDAO<Attributes>.self, from: Data(json.utf8))
    }

    @Test func fillsTheArtworkTemplate() {
        let artwork = AppleMusicArtworkDAO(url: "https://is1-ssl.mzstatic.com/image/thumb/a/{w}x{h}bb.jpg")
        #expect(artwork.url(side: 400)?.absoluteString == "https://is1-ssl.mzstatic.com/image/thumb/a/400x400bb.jpg")
    }

    @Test func leavesOutArtworkThatIsNotAWebURL() {
        #expect(AppleMusicArtworkDAO(url: "musicKit://artwork/1/{w}x{h}").url(side: 400) == nil)
    }

    @Test func decodesLibraryPlaylists() throws {
        let page = try Self.decode("""
        {"data": [
            {"id": "p.vMO5BZKFN4369", "type": "library-playlists",
             "attributes": {"name": "Fiesta", "artwork": {"url": "https://example.com/{w}x{h}.jpg"}}},
            {"id": "p.rXAJLqVCO1X0D", "type": "library-playlists", "attributes": {"name": "Sin portada"}},
            {"id": "p.noAttributes", "type": "library-playlists"}
        ]}
        """, as: AppleMusicLibraryPlaylistAttributesDAO.self)

        let items = page.data.compactMap { PlaylistsItemDAO(libraryPlaylist: $0, artworkSide: 400) }

        #expect(items.map(\.id) == ["p.vMO5BZKFN4369", "p.rXAJLqVCO1X0D"])
        #expect(items.first?.artworkURL?.absoluteString == "https://example.com/400x400.jpg")
        #expect(items.last?.artworkURL == nil)
        #expect(items.allSatisfy { $0.curatorName == nil })
    }

    @Test func keepsOnlySongsWithWebArtwork() throws {
        let page = try Self.decode("""
        {"data": [
            {"id": "i.ldDQRWEtv2bB8", "type": "library-songs",
             "attributes": {"name": "Billie Jean", "artistName": "Michael Jackson",
                            "artwork": {"url": "https://example.com/{w}x{h}.jpg"}}},
            {"id": "i.JL1aKERtDxY5b", "type": "library-songs",
             "attributes": {"name": "Uploaded", "artistName": "Me"}}
        ], "next": "/v1/me/library/playlists/p.1/tracks?offset=100"}
        """, as: AppleMusicSongAttributesDAO.self)

        let songs = page.data.compactMap { SongItemDAO(song: $0, artworkSide: 400) }

        #expect(songs.map(\.title) == ["Billie Jean"])
        #expect(songs.first?.artworkURL.absoluteString == "https://example.com/400x400.jpg")
        #expect(page.next != nil)
    }
}
