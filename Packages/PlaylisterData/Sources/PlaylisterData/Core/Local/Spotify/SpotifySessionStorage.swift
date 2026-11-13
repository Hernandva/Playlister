import Foundation
import Security

/// Where the Spotify tokens live between launches. Internal, so tests can use memory instead of the keychain.
protocol SpotifySessionStorageProtocol: Sendable {
    func load() -> SpotifySessionDAO?
    func save(_ session: SpotifySessionDAO) throws
    func delete()
}

enum SpotifySessionStorageError: Error, Equatable, Sendable {
    case keychain(OSStatus)
}

/// Keeps the tokens in the keychain, not in `UserDefaults`: they give access to the user's account.
/// The item is a generic password of service `playlisterData.spotify` and account `session`, saved as JSON.
struct SpotifyKeychainSessionStorage: SpotifySessionStorageProtocol {
    static let service = "playlisterData.spotify"
    static let account = "session"

    func load() -> SpotifySessionDAO? {
        var query = Self.baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(SpotifySessionDAO.self, from: data)
    }

    func save(_ session: SpotifySessionDAO) throws {
        let data = try JSONEncoder().encode(session)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        var status = SecItemUpdate(Self.baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(Self.baseQuery.merging(attributes) { $1 } as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw SpotifySessionStorageError.keychain(status)
        }
    }

    func delete() {
        SecItemDelete(Self.baseQuery as CFDictionary)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
