@testable import Networking
import Testing

private struct FakeLoginService: LoginServiceProtocol {
    let error: LoginError?

    func login(with provider: MusicProvider) async throws {
        if let error {
            throw error
        }
    }
}

struct LoginRepositoryTests {
    @Test func forwardsTheLoginToTheProviderService() async throws {
        let repository = LoginRepository(services: [.appleMusic: FakeLoginService(error: nil)])
        try await repository.login(with: .appleMusic)
    }

    @Test func forwardsTheErrorOfTheProviderService() async {
        let repository = LoginRepository(services: [.appleMusic: FakeLoginService(error: .subscriptionRequired)])
        await #expect(throws: LoginError.subscriptionRequired) {
            try await repository.login(with: .appleMusic)
        }
    }

    @Test func rejectsAProviderWithoutService() async {
        let repository = LoginRepository(services: [:])
        await #expect(throws: LoginError.unsupportedProvider(.spotify)) {
            try await repository.login(with: .spotify)
        }
    }
}
