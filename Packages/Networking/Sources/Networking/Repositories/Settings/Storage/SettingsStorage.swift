import Foundation

/// Local storage of the Settings repository. Internal.
protocol SettingsStorageProtocol: Sendable {
    /// The stored settings, or `nil` when there are none or they cannot be read.
    func settings() -> GameSettingsDAO?
    func saveSettings(_ settings: GameSettingsDAO) throws
}

/// Keeps the game settings as JSON in `UserDefaults`.
struct SettingsUserDefaultsStorage: SettingsStorageProtocol {
    /// Stable key: it must not change between versions, or the saved settings are lost.
    static let key = "networking.settings"

    /// `UserDefaults` is not `Sendable`, so the storage keeps the suite name and opens it on each access.
    /// `nil` uses the standard defaults.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    func settings() -> GameSettingsDAO? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(GameSettingsDAO.self, from: data)
    }

    func saveSettings(_ settings: GameSettingsDAO) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(settings)
        } catch {
            throw SettingsError.storageFailed
        }
        defaults.set(data, forKey: Self.key)
    }
}
