import Foundation
@testable import Networking
import Testing

private struct FakeLastPlaylistRequest: LastPlaylistRequestProtocol {
    let provider: MusicProvider
}

struct LastPlaylistRepositoryTests {
    private static let playlist = LastPlaylistItemDAO(
        id: "pl.123",
        name: "Hitster España",
        songCount: 312,
        coverURLs: [URL(string: "https://example.com/cover.jpg")].compactMap { $0 }
    )

    /// A repository on its own empty `UserDefaults` suite, so tests never share data.
    private static func makeRepository() -> LastPlaylistRepository {
        let suiteName = "LastPlaylistRepositoryTests.\(UUID().uuidString)"
        return LastPlaylistRepository(storage: LastPlaylistUserDefaultsStorage(suiteName: suiteName))
    }

    @Test func returnsNoPlaylistWhenNoneWasSaved() async throws {
        let repository = Self.makeRepository()

        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.provider == .appleMusic)
        #expect(response.lastPlaylist == nil)
    }

    @Test func returnsTheSavedPlaylistOfTheProvider() async throws {
        let repository = Self.makeRepository()

        try await repository.saveLastPlaylist(Self.playlist, for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.lastPlaylist?.id == "pl.123")
        #expect(response.lastPlaylist?.name == "Hitster España")
        #expect(response.lastPlaylist?.songCount == 312)
        #expect(response.lastPlaylist?.coverURLs == Self.playlist.coverURLs)
    }

    @Test func keepsEachProviderPlaylistApart() async throws {
        let repository = Self.makeRepository()

        try await repository.saveLastPlaylist(Self.playlist, for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.lastPlaylist == nil)
    }

    @Test func replacesThePreviousPlaylist() async throws {
        let repository = Self.makeRepository()
        let newer = LastPlaylistItemDAO(id: "pl.456", name: "Hitster 80s", songCount: 95, coverURLs: [])

        try await repository.saveLastPlaylist(Self.playlist, for: .spotify)
        try await repository.saveLastPlaylist(newer, for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.lastPlaylist?.id == "pl.456")
    }
}
