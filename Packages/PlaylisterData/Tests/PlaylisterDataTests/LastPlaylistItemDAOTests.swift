@testable import PlaylisterData
import Foundation
import Testing

struct LastPlaylistItemDAOTests {
    @Test func decodesAPlaylistSavedWithASongCount() throws {
        let json = Data(#"{"id":"pl.1","name":"Hitster España","songCount":312,"coverURLs":[]}"#.utf8)
        let playlist = try JSONDecoder().decode(LastPlaylistItemDAO.self, from: json)
        #expect(playlist.songCount == 312)
    }

    @Test func decodesAPlaylistSavedWithoutASongCount() throws {
        let json = Data(#"{"id":"pl.1","name":"Hitster España","coverURLs":[]}"#.utf8)
        let playlist = try JSONDecoder().decode(LastPlaylistItemDAO.self, from: json)
        #expect(playlist.songCount == nil)
    }
}
