import Foundation

/// Public API of the Settings repository. Features depend on this protocol, never on the concrete class.
public protocol SettingsRepositoryProtocol: Sendable {
    /// Reads the game settings of the music service in `request` from the local storage,
    /// or the default ones of that service when none were saved for it.
    func fetch(_ request: some SettingsRequestProtocol) async throws -> any SettingsResponseProtocol

    /// Stores `settings` as the game settings of `provider`, replacing the previous ones.
    /// Throws `SettingsError.storageFailed` when they cannot be written.
    func saveSettings(_ settings: some GameSettingsProtocol, for provider: MusicProvider) async throws
}

/// Public entry point of the game settings. Keeps them in the local storage, one set per provider.
public final class SettingsRepository: SettingsRepositoryProtocol {
    private let storage: any SettingsStorageProtocol

    public convenience init() {
        self.init(storage: SettingsUserDefaultsStorage())
    }

    /// Lets tests inject another storage.
    init(storage: any SettingsStorageProtocol) {
        self.storage = storage
    }

    public func fetch(_ request: some SettingsRequestProtocol) async throws -> any SettingsResponseProtocol {
        storage.settings(for: request.provider) ?? GameSettingsDAO.defaults(for: request.provider)
    }

    public func saveSettings(_ settings: some GameSettingsProtocol, for provider: MusicProvider) async throws {
        try storage.saveSettings(GameSettingsDAO(settings), for: provider)
    }
}
