import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeViewData)
        case failed(String)
    }

    /// Music services the player can sign in with.
    enum Provider: Sendable {
        case spotify
        case appleMusic
    }

    private(set) var state: State = .idle

    private let useCase: any HomeUseCaseProtocol
    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
        self.useCase = dependencies.makeUseCase()
    }

    /// Starts the official sign-in of `provider`.
    /// Not wired yet: it will call the Spotify / MusicKit authorisation use case once that repository exists.
    func signIn(with provider: Provider) {}

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.execute())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
