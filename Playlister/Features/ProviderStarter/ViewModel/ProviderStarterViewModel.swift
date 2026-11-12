import Foundation
import Observation

@MainActor
@Observable
final class ProviderStarterViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: ProviderStarterViewData

    private let useCase: any ProviderStarterUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ProviderStarterDependencies) {
        let provider = ProviderStarterViewData.Provider(dependencies.resolveProvider())
        self.viewData = ProviderStarterViewData(provider: provider)
        self.useCase = dependencies.resolveUseCase()
    }

    /// The music service the user signed in with, known before its data loads.
    var provider: ProviderStarterViewData.Provider {
        viewData.provider
    }

    /// Text of the badge at the top: «Spotify connected».
    var connectedTitle: String {
        String(localized: "providerStarter.connected \(provider.displayName)")
    }

    /// The playlist the game starts with, or `nil` while it loads or when there is none.
    var lastPlaylist: ProviderStarterViewData.Playlist? {
        state == .loaded ? viewData.lastPlaylist : nil
    }

    /// `true` once the data loaded and no playlist has been chosen yet with this music service.
    var needsPlaylist: Bool {
        state == .loaded && viewData.lastPlaylist == nil
    }

    /// Song count under the playlist name: «312 songs».
    func songCountText(for playlist: ProviderStarterViewData.Playlist) -> String {
        String(localized: "providerStarter.lastPlaylist.songs \(playlist.songCount)")
    }

    func load() async {
        state = .loading
        do {
            viewData.lastPlaylist = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "providerStarter.error \(provider.displayName)"))
        }
    }
}
