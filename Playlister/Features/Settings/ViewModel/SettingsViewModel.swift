import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: SettingsViewData
    /// Shown at the bottom when a change could not be saved.
    private(set) var saveErrorMessage: String?

    private let settingsUseCase: any SettingsUseCaseProtocol
    private let bingoLevelsUseCase: any BingoLevelsUseCaseProtocol
    private let saveSettingsUseCase: any SaveSettingsUseCaseProtocol
    private let signOut: @MainActor () -> Void
    /// The last save, so each one waits for the previous and the newest settings are written last.
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: SettingsDependencies) {
        self.viewData = SettingsViewData(provider: SettingsViewData.Provider(dependencies.resolveProvider()))
        self.settingsUseCase = dependencies.resolveSettingsUseCase()
        self.bingoLevelsUseCase = dependencies.resolveBingoLevelsUseCase()
        self.saveSettingsUseCase = dependencies.resolveSaveSettingsUseCase()
        self.signOut = dependencies.resolveSignOut()
    }

    // MARK: Settings, bound to the controls. Each change is saved right away.

    var playback: SettingsViewData.Playback {
        get { viewData.game?.playback ?? .clip }
        set { update { $0.playback = newValue } }
    }

    /// Length of a clip, as the slider needs it.
    var clipSeconds: Double {
        get { Double(viewData.game?.clipSeconds ?? SettingsViewData.Game.clipSecondsRange.lowerBound) }
        set { update { $0.clipSeconds = Int(newValue.rounded()) } }
    }

    var clipStart: SettingsViewData.ClipStart {
        get { viewData.game?.clipStart ?? .random }
        set { update { $0.clipStart = newValue } }
    }

    var gameMode: SettingsViewData.GameMode {
        get { viewData.game?.mode ?? .classic }
        set { update { $0.mode = newValue } }
    }

    /// Identifier of the selected Bingo level, as the segmented control needs it.
    var bingoLevel: String {
        get { viewData.game?.bingoLevel ?? "" }
        set { update { $0.bingoLevel = newValue } }
    }

    /// The Bingo levels from the repository, for the level selector.
    var bingoLevels: [SettingsViewData.BingoLevel] {
        viewData.bingoLevels
    }

    /// Categories of the selected level, with their names in it.
    var bingoCategories: [SettingsViewData.BingoCategory] {
        viewData.bingoLevels.first { $0.id == bingoLevel }?.categories ?? []
    }

    // MARK: Texts

    /// Value next to «Length»: «20 s».
    var clipSecondsText: String {
        Self.secondsText(Int(clipSeconds))
    }

    static func secondsText(_ seconds: Int) -> String {
        String(localized: "settings.playback.seconds \(seconds)")
    }

    /// What each round will play, under the Playback section.
    var playbackFooter: String {
        let seconds = Int(clipSeconds)
        switch (playback, clipStart) {
        case (.fullSong, _): return String(localized: "settings.playback.footer.fullSong")
        case (.clip, .beginning): return String(localized: "settings.playback.footer.clip.beginning \(seconds)")
        case (.clip, .random): return String(localized: "settings.playback.footer.clip.random \(seconds)")
        }
    }

    /// Name of the music service in the Account section.
    var providerName: String {
        viewData.provider.displayName
    }

    // MARK: Actions

    /// «Sign out»: goes back to Home.
    func didTapSignOut() {
        signOut()
    }

    func load() async {
        state = .loading
        viewData.bingoLevels = await bingoLevelsUseCase.execute()
        do {
            viewData.game = try await settingsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "settings.error"))
        }
    }
}

private extension SettingsViewModel {
    /// Applies `change` to the loaded settings and saves them when they changed.
    func update(_ change: (inout SettingsViewData.Game) -> Void) {
        guard var game = viewData.game else { return }
        change(&game)
        guard game != viewData.game else { return }
        viewData.game = game
        save(game)
    }

    func save(_ game: SettingsViewData.Game) {
        let previous = saveTask
        saveTask = Task { [saveSettingsUseCase] in
            await previous?.value
            do {
                try await saveSettingsUseCase.execute(game: game)
                saveErrorMessage = nil
            } catch {
                saveErrorMessage = String(localized: "settings.saveError")
            }
        }
    }
}
