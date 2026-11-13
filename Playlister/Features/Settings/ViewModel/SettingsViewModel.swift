import Foundation
import Observation
import PlaylisterUI

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
    private let saveSettingsUseCase: any SaveSettingsUseCaseProtocol
    private let signOut: @MainActor () -> Void
    /// The last save, so each one waits for the previous and the newest settings are written last.
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: SettingsDependencies) {
        self.viewData = SettingsViewData(provider: SettingsViewData.Provider(dependencies.resolveProvider()))
        self.settingsUseCase = dependencies.resolveSettingsUseCase()
        self.saveSettingsUseCase = dependencies.resolveSaveSettingsUseCase()
        self.signOut = dependencies.resolveSignOut()
    }

    // MARK: Settings, bound to the controls. Each change is saved right away.

    /// `true` in free mode: the Playback section is shown but cannot be changed.
    var isPlaybackLocked: Bool {
        viewData.provider.locksPlayback
    }

    var playback: SettingsViewData.Playback {
        get { viewData.game?.playback ?? .clip }
        set { updatePlayback { $0.playback = newValue } }
    }

    /// Length of a clip, as the slider needs it.
    var clipSeconds: Double {
        get { Double(viewData.game?.clipSeconds ?? SettingsViewData.Game.clipSecondsRange.lowerBound) }
        set { updatePlayback { $0.clipSeconds = Int(newValue.rounded()) } }
    }

    var clipStart: SettingsViewData.ClipStart {
        get { viewData.game?.clipStart ?? .random }
        set { updatePlayback { $0.clipStart = newValue } }
    }

    var gameMode: SettingsViewData.GameMode {
        get { viewData.game?.mode ?? .classic }
        set { update { $0.mode = newValue } }
    }

    var bingoLevel: DSBingoLevel {
        get { viewData.game?.bingoLevel ?? .beginner }
        set { update { $0.bingoLevel = newValue } }
    }

    func isCategoryOn(_ category: DSBingoCategory) -> Bool {
        !(viewData.game?.disabledCategories[bingoLevel]?.contains(category) ?? false)
    }

    /// Turns `category` on or off for the current level. The last category that is on cannot be turned off.
    func setCategory(_ category: DSBingoCategory, isOn: Bool) {
        guard isOn || canTurnOff(category) else { return }
        let level = bingoLevel
        update { game in
            var disabled = game.disabledCategories[level, default: []]
            if isOn {
                disabled.remove(category)
            } else {
                disabled.insert(category)
            }
            game.disabledCategories[level] = disabled.isEmpty ? nil : disabled
        }
    }

    /// `false` for the only category that is on: cards need at least one.
    func canTurnOff(_ category: DSBingoCategory) -> Bool {
        !isCategoryOn(category) || activeCategoryCount > 1
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
        if isPlaybackLocked {
            return String(localized: "settings.playback.footer.free \(seconds)")
        }
        switch (playback, clipStart) {
        case (.fullSong, _): return String(localized: "settings.playback.footer.fullSong")
        case (.clip, .beginning): return String(localized: "settings.playback.footer.clip.beginning \(seconds)")
        case (.clip, .random): return String(localized: "settings.playback.footer.clip.random \(seconds)")
        }
    }

    /// How many categories are on, under the Bingo categories section.
    var bingoFooter: String {
        String(localized: "settings.bingo.footer \(activeCategoryCount) \(DSBingoCategory.allCases.count)")
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
        do {
            viewData.game = try await settingsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "settings.error"))
        }
    }
}

private extension SettingsViewModel {
    var activeCategoryCount: Int {
        DSBingoCategory.allCases.filter(isCategoryOn).count
    }

    /// Applies a change of the Playback section, unless free mode locks it.
    func updatePlayback(_ change: (inout SettingsViewData.Game) -> Void) {
        guard !isPlaybackLocked else { return }
        update(change)
    }

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
