import Foundation
import PlaylisterData

/// Dependency injection container of ProviderStarter: the only place where its concrete types are built.
@MainActor
final class ProviderStarterDependencies {
    private let provider: MusicProvider
    private let signOut: @MainActor () -> Void
    private let repository: any LastPlaylistRepositoryProtocol

    /// - Parameters:
    ///   - provider: The music service the user signed in with in Home.
    ///   - signOut: Goes back to Home from any screen opened from ProviderStarter (Settings › Sign out).
    init(
        provider: MusicProvider,
        signOut: @escaping @MainActor () -> Void,
        repository: any LastPlaylistRepositoryProtocol = LastPlaylistRepository()
    ) {
        self.provider = provider
        self.signOut = signOut
        self.repository = repository
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// Goes back to Home. Settings receives it for «Sign out».
    func resolveSignOut() -> @MainActor () -> Void {
        signOut
    }

    func resolveRepository() -> any LastPlaylistRepositoryProtocol {
        repository
    }

    func resolveLastPlaylistUseCase() -> any LastPlaylistUseCaseProtocol {
        LastPlaylistUseCase(dependencies: self)
    }

    func resolveSaveLastPlaylistUseCase() -> any SaveLastPlaylistUseCaseProtocol {
        SaveLastPlaylistUseCase(dependencies: self)
    }

    func resolveViewModel() -> ProviderStarterViewModel {
        ProviderStarterViewModel(dependencies: self)
    }
}
