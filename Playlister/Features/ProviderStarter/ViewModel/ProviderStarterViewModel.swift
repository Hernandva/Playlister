import Foundation
import Observation

@MainActor
@Observable
final class ProviderStarterViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(ProviderStarterViewData)
        case failed(String)
    }

    private(set) var state: State = .idle
    /// The music service the user signed in with, known before its data loads.
    let provider: ProviderStarterViewData.Provider

    private let useCase: any ProviderStarterUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ProviderStarterDependencies) {
        self.provider = ProviderStarterViewData.Provider(dependencies.resolveProvider())
        self.useCase = dependencies.resolveUseCase()
    }

    /// Text of the badge at the top: «Spotify connected».
    var connectedTitle: String {
        String(localized: "providerStarter.connected \(provider.displayName)")
    }

    /// The playlist the game starts with, or `nil` while it loads or when there is none.
    var lastPlaylist: ProviderStarterViewData.Playlist? {
        guard case .loaded(let viewData) = state else { return nil }
        return viewData.lastPlaylist
    }

    /// Song count under the playlist name: «312 songs».
    func songCountText(for playlist: ProviderStarterViewData.Playlist) -> String {
        String(localized: "providerStarter.lastPlaylist.songs \(playlist.songCount)")
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.execute())
        } catch {
            state = .failed(String(localized: "providerStarter.error \(provider.displayName)"))
        }
    }
}
