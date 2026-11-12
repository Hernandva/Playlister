import Foundation
import Networking

/// Dependency injection container of ProviderStarter: the only place where its concrete types are built.
@MainActor
final class ProviderStarterDependencies {
    private let provider: MusicProvider
    private let repository: any ProviderRepositoryProtocol

    /// - Parameter provider: The music service the user signed in with in Home.
    init(provider: MusicProvider, repository: any ProviderRepositoryProtocol = ProviderRepository()) {
        self.provider = provider
        self.repository = repository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    func resolveRepository() -> any ProviderRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any ProviderStarterUseCaseProtocol {
        ProviderStarterUseCase(dependencies: self)
    }

    func resolveViewModel() -> ProviderStarterViewModel {
        ProviderStarterViewModel(dependencies: self)
    }
}
