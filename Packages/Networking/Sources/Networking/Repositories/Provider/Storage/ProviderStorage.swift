import Foundation

/// Local storage of the Provider repository: one last playlist per music service. Internal.
protocol ProviderStorageProtocol: Sendable {
    /// The stored playlist of `provider`, or `nil` when there is none or it cannot be read.
    func lastPlaylist(for provider: MusicProvider) -> ProviderPlaylistDAO?
    func saveLastPlaylist(_ playlist: ProviderPlaylistDAO, for provider: MusicProvider) throws
}

/// Keeps each provider's last playlist as JSON in `UserDefaults`, under its own key.
struct ProviderUserDefaultsStorage: ProviderStorageProtocol {
    private static let keyPrefix = "networking.provider.lastPlaylist."

    /// `UserDefaults` is not `Sendable`, so the storage keeps the suite name and opens it on each access.
    /// `nil` uses the standard defaults.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    func lastPlaylist(for provider: MusicProvider) -> ProviderPlaylistDAO? {
        guard let data = defaults.data(forKey: Self.key(for: provider)) else { return nil }
        return try? JSONDecoder().decode(ProviderPlaylistDAO.self, from: data)
    }

    func saveLastPlaylist(_ playlist: ProviderPlaylistDAO, for provider: MusicProvider) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(playlist)
        } catch {
            throw ProviderError.storageFailed
        }
        defaults.set(data, forKey: Self.key(for: provider))
    }

    /// Stable key per provider: it must not change between versions, or saved playlists are lost.
    static func key(for provider: MusicProvider) -> String {
        switch provider {
        case .spotify: keyPrefix + "spotify"
        case .appleMusic: keyPrefix + "appleMusic"
        }
    }
}
