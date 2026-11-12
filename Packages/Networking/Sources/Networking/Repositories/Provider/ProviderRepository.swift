import Foundation

/// Public API of the Provider repository. Features depend on this protocol, never on the concrete class.
public protocol ProviderRepositoryProtocol: Sendable {
    /// Reads the data of the music service in `request` from the local storage.
    func fetch(_ request: some ProviderRequestProtocol) async throws -> any ProviderResponseProtocol

    /// Stores `playlist` as the last playlist played with `provider`, replacing the previous one.
    /// Throws `ProviderError.storageFailed` when it cannot be written.
    func saveLastPlaylist(_ playlist: some ProviderPlaylistProtocol, for provider: MusicProvider) async throws
}

/// Public entry point of the music services' data. Keeps the last playlist of each provider in the local storage.
public final class ProviderRepository: ProviderRepositoryProtocol {
    private let storage: any ProviderStorageProtocol

    public convenience init() {
        self.init(storage: ProviderUserDefaultsStorage())
    }

    /// Lets tests inject another storage.
    init(storage: any ProviderStorageProtocol) {
        self.storage = storage
    }

    public func fetch(_ request: some ProviderRequestProtocol) async throws -> any ProviderResponseProtocol {
        ProviderResponseDAO(provider: request.provider, playlist: storage.lastPlaylist(for: request.provider))
    }

    public func saveLastPlaylist(_ playlist: some ProviderPlaylistProtocol, for provider: MusicProvider) async throws {
        try storage.saveLastPlaylist(ProviderPlaylistDAO(playlist), for: provider)
    }
}
