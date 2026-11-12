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

    /// `true` while Play saves the selected playlist.
    private(set) var isStartingGame = false
    /// Shown under Play when the selected playlist could not be saved.
    private(set) var playErrorMessage: String?
    /// `true` while the sheet that offers to change the music service is shown.
    var isChangeProviderSheetPresented = false
    /// Set when the user chose to go back to Home: the view pops once the sheet has closed.
    private(set) var wantsToReturnHome = false

    private let lastPlaylistUseCase: any LastPlaylistUseCaseProtocol
    private let saveLastPlaylistUseCase: any SaveLastPlaylistUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ProviderStarterDependencies) {
        let provider = ProviderStarterViewData.Provider(dependencies.resolveProvider())
        self.viewData = ProviderStarterViewData(provider: provider)
        self.lastPlaylistUseCase = dependencies.resolveLastPlaylistUseCase()
        self.saveLastPlaylistUseCase = dependencies.resolveSaveLastPlaylistUseCase()
    }

    /// The music service the user signed in with, known before its data loads.
    var provider: ProviderStarterViewData.Provider {
        viewData.provider
    }

    /// Text of the badge at the top: «Spotify connected».
    var connectedTitle: String {
        String(localized: "providerStarter.connected \(provider.displayName)")
    }

    /// The playlist shown in the card and played by Play: the selected one, else the last one.
    /// `nil` while it loads or when there is none.
    var selectedPlaylist: ProviderStarterViewData.Playlist? {
        guard state == .loaded else { return nil }
        return viewData.selectedPlaylist ?? viewData.lastPlaylist
    }

    /// `true` when the card shows a playlist chosen in the selector, not the last one played.
    var isShowingSelection: Bool {
        viewData.selectedPlaylist != nil
    }

    /// `true` once the data loaded and there is neither a selected nor a last playlist.
    var needsPlaylist: Bool {
        state == .loaded && selectedPlaylist == nil
    }

    /// Title of the sheet that offers to change the music service.
    var changeProviderSheetTitle: String {
        String(localized: "providerStarter.changeProvider.title")
    }

    /// Explanation of the sheet: the service in use and that Home lets the user pick another one.
    var changeProviderSheetMessage: String {
        String(localized: "providerStarter.changeProvider.message \(provider.displayName)")
    }

    /// The badge at the top was tapped: offers to go back to Home to change the music service.
    func didTapProviderBadge() {
        wantsToReturnHome = false
        isChangeProviderSheetPresented = true
    }

    /// «Back to Home» in the sheet: closes it and asks the view to go back once it has closed.
    func didChooseReturnHome() {
        wantsToReturnHome = true
        isChangeProviderSheetPresented = false
    }

    /// «Stay here» in the sheet.
    func dismissChangeProviderSheet() {
        isChangeProviderSheetPresented = false
    }

    /// Song count under the playlist name: «312 songs».
    func songCountText(for playlist: ProviderStarterViewData.Playlist) -> String {
        String(localized: "providerStarter.selectedPlaylist.songs \(playlist.songCount)")
    }

    /// Called by the playlist selector with the playlist the user chose.
    func selectPlaylist(_ playlist: ProviderStarterViewData.Playlist) {
        viewData.selectedPlaylist = playlist
        playErrorMessage = nil
    }

    /// Play: saves the selected playlist as the last playlist, then starts the game.
    func didTapPlay() async {
        guard !isStartingGame, selectedPlaylist != nil else { return }
        if let selected = viewData.selectedPlaylist, selected != viewData.lastPlaylist {
            isStartingGame = true
            defer { isStartingGame = false }
            do {
                try await saveLastPlaylistUseCase.execute(playlist: selected)
                viewData.lastPlaylist = selected
                playErrorMessage = nil
            } catch {
                playErrorMessage = String(localized: "providerStarter.play.saveError")
                return
            }
        }
        // Opens the game with `selectedPlaylist` once the Game feature exists.
    }

    func load() async {
        state = .loading
        do {
            viewData.lastPlaylist = try await lastPlaylistUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "providerStarter.error \(provider.displayName)"))
        }
    }
}
