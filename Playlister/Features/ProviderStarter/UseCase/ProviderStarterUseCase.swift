import Foundation
import Networking

protocol ProviderStarterUseCaseProtocol: Sendable {
    /// Reads the data of the music service the user signed in with.
    func execute() async throws -> ProviderStarterViewData
}

/// Request sent to the Provider repository: the music service the user signed in with in Home.
struct ProviderStarterRequest: ProviderRequestProtocol {
    let provider: MusicProvider
}

/// Business logic of ProviderStarter: calls the Provider repository public API and maps the response into ViewData.
struct ProviderStarterUseCase: ProviderStarterUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any ProviderRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `ProviderStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ProviderStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> ProviderStarterViewData {
        let response = try await repository.fetch(ProviderStarterRequest(provider: provider))
        return ProviderStarterViewData(response: response)
    }
}
