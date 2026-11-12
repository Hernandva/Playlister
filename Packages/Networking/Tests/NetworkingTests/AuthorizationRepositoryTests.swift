@testable import Networking
import Testing

private struct FakeAuthorizationService: AuthorizationServiceProtocol {
    let status: AuthorizationStatus

    func requestAuthorization(for provider: MusicProvider) async throws -> AuthorizationStatus {
        status
    }
}

struct AuthorizationRepositoryTests {
    @Test func forwardsTheRequestToTheProviderService() async throws {
        let repository = AuthorizationRepository(services: [.appleMusic: FakeAuthorizationService(status: .denied)])
        #expect(try await repository.requestAuthorization(for: .appleMusic) == .denied)
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = AuthorizationRepository(services: [:])
        await #expect(throws: AuthorizationError.unsupportedProvider(.spotify)) {
            try await repository.requestAuthorization(for: .spotify)
        }
    }
}
