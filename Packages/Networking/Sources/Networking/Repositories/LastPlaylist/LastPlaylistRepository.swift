import Foundation

/// Public API of the Provider repository. Features depend on this protocol, never on the concrete class.
public protocol LastPlaylistRepositoryProtocol: Sendable {
    /// Reads the data of the music service in `request` from the local storage.
    func fetch(_ request: some LastPlaylistRequestProtocol) async throws -> any LastPlaylistResponseProtocol

    /// Stores `playlist` as the last playlist played with `provider`, replacing the previous one.
    /// Throws `LastPlaylistError.storageFailed` when it cannot be written.
    func saveLastPlaylist(_ playlist: some LastPlaylistItemProtocol, for provider: MusicProvider) async throws
}

/// Public entry point of the music services' data. Keeps the last playlist of each provider in the local storage.
public final class LastPlaylistRepository: LastPlaylistRepositoryProtocol {
    private let storage: any LastPlaylistStorageProtocol

    public convenience init() {
        self.init(storage: LastPlaylistUserDefaultsStorage())
    }

    /// Lets tests inject another storage.
    init(storage: any LastPlaylistStorageProtocol) {
        self.storage = storage
    }

    public func fetch(_ request: some LastPlaylistRequestProtocol) async throws -> any LastPlaylistResponseProtocol {
        LastPlaylistResponseDAO(provider: request.provider, playlist: storage.lastPlaylist(for: request.provider))
    }

    public func saveLastPlaylist(_ playlist: some LastPlaylistItemProtocol, for provider: MusicProvider) async throws {
        try storage.saveLastPlaylist(LastPlaylistItemDAO(playlist), for: provider)
    }
}
