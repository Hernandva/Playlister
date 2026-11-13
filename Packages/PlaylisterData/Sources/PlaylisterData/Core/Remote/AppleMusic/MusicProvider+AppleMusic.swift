import Foundation

/// Providers served by the Apple Music services. Free mode uses the same authorisation, login, playlists,
/// songs and player as Apple Music, so every Apple Music service accepts both.
extension MusicProvider {
    static let appleMusicProviders: [MusicProvider] = [.appleMusic, .free]

    /// `true` when the Apple Music services serve this provider.
    var usesAppleMusic: Bool {
        Self.appleMusicProviders.contains(self)
    }

    /// Registers `service` under every provider served by Apple Music, for a repository's `services`.
    static func appleMusicServices<Service>(_ service: Service) -> [MusicProvider: Service] {
        Dictionary(uniqueKeysWithValues: appleMusicProviders.map { ($0, service) })
    }
}
