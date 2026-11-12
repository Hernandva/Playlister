import Foundation

/// Public API of the Settings repository. Features depend on this protocol, never on the concrete class.
public protocol SettingsRepositoryProtocol: Sendable {
    /// Reads the game settings from the local storage, or the default ones when none were saved.
    func fetch(_ request: some SettingsRequestProtocol) async throws -> any SettingsResponseProtocol

    /// Stores `settings`, replacing the previous ones.
    /// Throws `SettingsError.storageFailed` when they cannot be written.
    func saveSettings(_ settings: some GameSettingsProtocol) async throws
}

/// Public entry point of the game settings. Keeps them in the local storage; they are the same for every provider.
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
        storage.settings() ?? GameSettingsDAO.defaults
    }

    public func saveSettings(_ settings: some GameSettingsProtocol) async throws {
        try storage.saveSettings(GameSettingsDAO(settings))
    }
}
