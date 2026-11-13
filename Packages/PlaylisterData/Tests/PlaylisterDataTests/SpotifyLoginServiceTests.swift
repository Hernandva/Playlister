import Foundation
@testable import PlaylisterData
import Testing

private actor FakeSpotifySession: SpotifySessionProtocol {
    private let error: (any Error)?
    private(set) var invalidations = 0

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func accessToken(interactive: Bool) async throws -> String {
        if let error {
            throw error
        }
        return "token-\(invalidations)"
    }

    func invalidate() {
        invalidations += 1
    }
}

/// Answers each call with the next result; the last one repeats.
private actor FakeSpotifyAPIClient: SpotifyAPIClientProtocol {
    private var results: [Result<SpotifyUserDAO, NetworkError>]

    init(_ results: [Result<SpotifyUserDAO, NetworkError>]) {
        self.results = results
    }

    func get<Response: Decodable & Sendable>(_ path: String, accessToken: String) async throws -> Response {
        let result = results.count > 1 ? results.removeFirst() : results[0]
        guard let user = try result.get() as? Response else {
            throw NetworkError.unknownService(path)
        }
        return user
    }
}

struct SpotifyLoginServiceTests {
    private let premium = SpotifyUserDAO(id: "user", product: "premium")

    @Test func acceptsAPremiumAccount() async throws {
        let service = SpotifyLoginService(
            session: FakeSpotifySession(),
            client: FakeSpotifyAPIClient([.success(premium)])
        )
        try await service.login(with: .spotify)
    }

    @Test func requiresPremium() async {
        let free = SpotifyUserDAO(id: "user", product: "free")
        let service = SpotifyLoginService(session: FakeSpotifySession(), client: FakeSpotifyAPIClient([.success(free)]))
        await #expect(throws: LoginError.subscriptionRequired) {
            try await service.login(with: .spotify)
        }
    }

    @Test func aCancelledSignInIsNotAuthorized() async {
        let service = SpotifyLoginService(
            session: FakeSpotifySession(error: SpotifyAuthError.cancelled),
            client: FakeSpotifyAPIClient([.success(premium)])
        )
        await #expect(throws: LoginError.notAuthorized) {
            try await service.login(with: .spotify)
        }
    }

    @Test func signsInAgainWhenTheTokenIsRejected() async throws {
        let session = FakeSpotifySession()
        let client = FakeSpotifyAPIClient([.failure(.unacceptableStatusCode(401)), .success(premium)])
        try await SpotifyLoginService(session: session, client: client).login(with: .spotify)
        #expect(await session.invalidations == 1)
    }

    @Test func otherFailuresAreUnavailable() async {
        let service = SpotifyLoginService(
            session: FakeSpotifySession(),
            client: FakeSpotifyAPIClient([.failure(.unacceptableStatusCode(500))])
        )
        await #expect(throws: LoginError.unavailable) {
            try await service.login(with: .spotify)
        }
    }

    @Test func rejectsOtherProviders() async {
        let service = SpotifyLoginService(
            session: FakeSpotifySession(),
            client: FakeSpotifyAPIClient([.success(premium)])
        )
        await #expect(throws: LoginError.unsupportedProvider(.appleMusic)) {
            try await service.login(with: .appleMusic)
        }
    }

    @Test func thePKCEChallengeIsTheSHA256OfTheVerifier() {
        // Example of RFC 7636, appendix B.
        let pkce = SpotifyPKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk", state: "state")
        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }
}
