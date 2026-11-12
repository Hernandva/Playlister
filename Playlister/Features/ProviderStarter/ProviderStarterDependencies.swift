import Foundation
import Networking

/// Dependency injection container of ProviderStarter: the only place where its concrete types are built.
@MainActor
final class ProviderStarterDependencies {
    private let provider: MusicProvider
    private let repository: any LastPlaylistRepositoryProtocol

    /// - Parameter provider: The music service the user signed in with in Home.
    init(provider: MusicProvider, repository: any LastPlaylistRepositoryProtocol = LastPlaylistRepository()) {
        self.provider = provider
        self.repository = repository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    func resolveRepository() -> any LastPlaylistRepositoryProtocol {
        repository
    }

    func resolveLastPlaylistUseCase() -> any LastPlaylistUseCaseProtocol {
        LastPlaylistUseCase(dependencies: self)
    }

    func resolveViewModel() -> ProviderStarterViewModel {
        ProviderStarterViewModel(dependencies: self)
    }
}
