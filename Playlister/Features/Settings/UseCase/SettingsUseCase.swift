import Foundation
import PlaylisterData
import PlaylisterUI

protocol SettingsUseCaseProtocol: Sendable {
    /// Returns only the game settings. The view model adds them to its `SettingsViewData`.
    func execute() async throws -> SettingsViewData.Game
}

/// Request sent to the Settings repository: the music service the user signed in with, which has its own settings.
struct SettingsRequest: SettingsRequestProtocol {
    let provider: MusicProvider
}

/// Business logic of Settings: reads the game settings of the signed-in music service through the Settings repository public API and returns
/// them mapped out of the PlaylisterData types.
struct SettingsUseCase: SettingsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `SettingsDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> SettingsViewData.Game {
        let response = try await repository.fetch(SettingsRequest(provider: provider))
        return Self.game(from: response)
    }
}

private extension SettingsUseCase {
    /// Maps SettingsResponseProtocol into the data the view model adds to its ViewData.
    static func game(from response: any SettingsResponseProtocol) -> SettingsViewData.Game {
        SettingsViewData.Game(
            playback: response.playbackMode == .fullSong ? .fullSong : .clip,
            clipSeconds: clipSeconds(response.clipSeconds),
            clipStart: response.clipStart == .beginning ? .beginning : .random,
            mode: response.gameMode == .bingo ? .bingo : .classic,
            bingoLevel: DSBingoLevel(response.bingoLevel),
            disabledCategories: Dictionary(
                uniqueKeysWithValues: response.disabledBingoCategories.map { level, categories in
                    (DSBingoLevel(level), Set(categories.map(DSBingoCategory.init)))
                }
            )
        )
    }

    /// Keeps a stored length inside the range and on a step of the slider.
    static func clipSeconds(_ seconds: Int) -> Int {
        let range = SettingsViewData.Game.clipSecondsRange
        let step = SettingsViewData.Game.clipSecondsStep
        let stepped = (seconds + step / 2) / step * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

extension DSBingoLevel {
    init(_ level: SettingsBingoLevel) {
        switch level {
        case .beginner: self = .beginner
        case .expert: self = .expert
        }
    }
}

extension DSBingoCategory {
    init(_ category: SettingsBingoCategory) {
        switch category {
        case .pink: self = .pink
        case .yellow: self = .yellow
        case .cyan: self = .cyan
        case .green: self = .green
        case .orange: self = .orange
        }
    }
}
