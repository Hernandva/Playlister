import Foundation

/// Local storage of the Settings repository: one set of game settings per music service. Internal.
protocol SettingsStorageProtocol: Sendable {
    /// The stored settings of `provider`, or `nil` when there are none or they cannot be read.
    func settings(for provider: MusicProvider) -> GameSettingsDAO?
    func saveSettings(_ settings: GameSettingsDAO, for provider: MusicProvider) throws
}

/// Keeps each provider's game settings as JSON in `UserDefaults`, under its own key.
struct SettingsUserDefaultsStorage: SettingsStorageProtocol {
    private static let keyPrefix = "playlisterData.settings."

    /// `UserDefaults` is not `Sendable`, so the storage keeps the suite name and opens it on each access.
    /// `nil` uses the standard defaults.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    func settings(for provider: MusicProvider) -> GameSettingsDAO? {
        guard let data = defaults.data(forKey: Self.key(for: provider)) else { return nil }
        return try? JSONDecoder().decode(GameSettingsDAO.self, from: data)
    }

    func saveSettings(_ settings: GameSettingsDAO, for provider: MusicProvider) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(settings)
        } catch {
            throw SettingsError.storageFailed
        }
        defaults.set(data, forKey: Self.key(for: provider))
    }

    /// Stable key per provider: it must not change between versions, or saved settings are lost.
    static func key(for provider: MusicProvider) -> String {
        switch provider {
        case .spotify: keyPrefix + "spotify"
        case .appleMusic: keyPrefix + "appleMusic"
        case .free: keyPrefix + "free"
        }
    }
}
