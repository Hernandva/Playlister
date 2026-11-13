import AuthenticationServices
import CryptoKit
import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Why Spotify's sign-in page did not give an authorisation code. Internal.
enum SpotifyAuthError: Error, Equatable, Sendable {
    /// The Info.plist has no `SpotifyClientID`.
    case missingClientID
    /// The user closed the sign-in page or refused the permissions.
    case cancelled
    /// The callback came without a code, or with a `state` that is not ours.
    case invalidCallback
    /// There is no session and the call may not show the sign-in page.
    case signInRequired
}

/// Shows Spotify's sign-in page and returns the authorisation code. Internal, so tests can fake it.
protocol SpotifyWebAuthenticatorProtocol: Sendable {
    /// Opens `url` and returns the URL Spotify redirects to (`playlister://spotify-callback?code=…`).
    func authenticate(url: URL, callbackScheme: String) async throws -> URL
}

/// Opens Spotify's page in `ASWebAuthenticationSession`, Apple's sheet for OAuth sign-ins.
struct SpotifyWebAuthenticator: SpotifyWebAuthenticatorProtocol {
    func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await SpotifyWebAuthenticationSession().start(url: url, callbackScheme: callbackScheme)
    }
}

/// Keeps the session and its presentation anchor alive while the sheet is shown.
@MainActor
private final class SpotifyWebAuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func start(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callback: .customScheme(callbackScheme)
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: SpotifyAuthError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? SpotifyAuthError.invalidCallback)
                }
            }
            session.presentationContextProvider = self
            self.session = session
            if !session.start() {
                continuation.resume(throwing: SpotifyAuthError.invalidCallback)
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first ?? ASPresentationAnchor()
        #else
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #endif
    }
}

/// PKCE pair of one sign-in: the verifier stays on the device, Spotify only sees its SHA-256 challenge.
struct SpotifyPKCE: Sendable {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    let verifier: String
    let challenge: String
    /// Random value echoed back by Spotify, to reject callbacks of other sign-ins.
    let state: String

    init() {
        self.init(verifier: Self.randomString(length: 64), state: Self.randomString(length: 16))
    }

    init(verifier: String, state: String) {
        self.verifier = verifier
        self.state = state
        let digest = SHA256.hash(data: Data(verifier.utf8))
        self.challenge = Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func randomString(length: Int) -> String {
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in alphabet.randomElement(using: &generator) ?? "a" })
    }
}
