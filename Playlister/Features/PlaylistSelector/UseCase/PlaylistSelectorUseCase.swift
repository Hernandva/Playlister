import Foundation
import PlaylisterData

protocol PlaylistSelectorUseCaseProtocol: Sendable {
    /// Returns only the data of the response. The view model adds it to its `PlaylistSelectorViewData`.
    func execute() async throws -> PlaylistSelectorViewData.Content
}

/// Request sent to the Playlists repository. Add the fields its public request protocol declares.
struct PlaylistSelectorRequest: PlaylistsRequestProtocol {}

/// Business logic of PlaylistSelector: calls the Playlists repository public API and returns only the data of its
/// response, mapped out of the PlaylisterData types.
struct PlaylistSelectorUseCase: PlaylistSelectorUseCaseProtocol {
    /// One of the service names declared in `PlaylistsRepository.configuration.serviceNames`.
    private let serviceName = ""

    private let repository: any PlaylistsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `PlaylistSelectorDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: PlaylistSelectorDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> PlaylistSelectorViewData.Content {
        let response = try await repository.fetch(PlaylistSelectorRequest(), serviceName: serviceName)
        return Self.content(from: response)
    }
}

private extension PlaylistSelectorUseCase {
    /// Maps the fields of PlaylistsResponseProtocol into the data the view model adds to its ViewData.
    static func content(from response: any PlaylistsResponseProtocol) -> PlaylistSelectorViewData.Content {
        PlaylistSelectorViewData.Content()
    }
}
