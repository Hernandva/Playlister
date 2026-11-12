import Foundation
import PlaylisterData

/// Dependency injection container of PlaylistSelector: the only place where its concrete types are built.
@MainActor
final class PlaylistSelectorDependencies {
    private let repository: any PlaylistsRepositoryProtocol

    init(repository: any PlaylistsRepositoryProtocol = PlaylistsRepository()) {
        self.repository = repository
    }

    func resolveRepository() -> any PlaylistsRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any PlaylistSelectorUseCaseProtocol {
        PlaylistSelectorUseCase(dependencies: self)
    }

    func resolveViewModel() -> PlaylistSelectorViewModel {
        PlaylistSelectorViewModel(dependencies: self)
    }
}
