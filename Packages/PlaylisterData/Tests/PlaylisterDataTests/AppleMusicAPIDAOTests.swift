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
        """, as: AppleMusicPlaylistAttributesDAO.self)

        let items = page.data.compactMap { PlaylistsItemDAO(playlist: $0, artworkSide: 400) }

        #expect(items.map(\.id) == ["p.vMO5BZKFN4369", "p.rXAJLqVCO1X0D"])
        #expect(items.first?.artworkURL?.absoluteString == "https://example.com/400x400.jpg")
        #expect(items.last?.artworkURL == nil)
        #expect(items.allSatisfy { $0.curatorName == nil })
    }

    @Test func decodesASearchWithCatalogPlaylists() throws {
        let json = """
        {"results": {"playlists": {
            "data": [{"id": "pl.u-DdANxEPFj4Jyvq", "type": "playlists",
                      "attributes": {"name": "Hitster", "curatorName": "Alguien",
                                     "artwork": {"url": "https://example.com/{w}x{h}.jpg"}}}],
            "next": "/v1/catalog/es/search?offset=25"
        }}}
        """
        let response = try JSONDecoder().decode(AppleMusicPlaylistsSearchDAO.self, from: Data(json.utf8))
        let page = try #require(response.results.playlists)
        let items = page.data.compactMap { PlaylistsItemDAO(playlist: $0, artworkSide: 400) }

        #expect(items.map(\.curatorName) == ["Alguien"])
        #expect(page.next != nil)
    }

    @Test func decodesASearchWithoutPlaylists() throws {
        let response = try JSONDecoder().decode(AppleMusicPlaylistsSearchDAO.self, from: Data(#"{"results": {}}"#.utf8))
        #expect(response.results.playlists == nil)
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

    @Test func listsSongsWithAndWithoutArtworkWithTheirDuration() throws {
        let page = try Self.decode("""
        {"data": [
            {"id": "i.1", "type": "library-songs",
             "attributes": {"name": "Billie Jean", "artistName": "Michael Jackson", "durationInMillis": 294000,
                            "artwork": {"url": "https://example.com/{w}x{h}.jpg"}}},
            {"id": "i.2", "type": "library-songs", "attributes": {"name": "Uploaded", "artistName": "Me"}},
            {"id": "i.3", "type": "library-songs"}
        ], "next": "/v1/me/library/playlists/p.1/tracks?offset=25", "meta": {"total": 312}}
        """, as: AppleMusicSongAttributesDAO.self)

        let songs = page.data.compactMap { PlaylistSongItemDAO(song: $0, artworkSide: 150) }

        #expect(songs.map(\.title) == ["Billie Jean", "Uploaded"])
        #expect(songs.first?.duration == 294)
        #expect(songs.first?.artworkURL?.absoluteString == "https://example.com/150x150.jpg")
        #expect(songs.last?.artworkURL == nil)
        #expect(songs.last?.duration == nil)
        #expect(page.meta?.total == 312)
    }
}
