import Foundation

/// Where and how Playlister signs in with Spotify (Authorization Code with PKCE, no client secret). Internal.
/// https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
struct SpotifyAuthConfiguration: Sendable, Equatable {
    /// Info.plist key with the Client ID of the app in the Spotify developer dashboard.
    static let clientIDInfoKey = "SpotifyClientID"
    /// Scheme of `redirectURI`, which `ASWebAuthenticationSession` listens to.
    static let callbackScheme = "playlister"

    static let authorizeURL = "https://accounts.spotify.com/authorize"
    static let tokenURL = "https://accounts.spotify.com/api/token"

    /// What Playlister asks for: the account (`product`, to check Premium), the playlists and the playback.
    /// They are asked for at once so the user does not have to consent again when the other repositories use them.
    static let scopes = [
        "user-read-private",
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-library-read",
        "user-read-playback-state",
        "user-modify-playback-state",
        "app-remote-control",
        "streaming"
    ]

    /// Client ID of the app. Empty when the Info.plist does not set it.
    let clientID: String
    /// Must be listed exactly like this in the Redirect URIs of the app in the Spotify developer dashboard.
    let redirectURI: String

    /// Reads the Client ID from the app's Info.plist (`SpotifyClientID`).
    static let main = SpotifyAuthConfiguration(
        clientID: Bundle.main.object(forInfoDictionaryKey: clientIDInfoKey) as? String ?? "",
        redirectURI: "\(callbackScheme)://spotify-callback"
    )
}
