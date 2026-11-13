import Foundation
import PlaylisterData

protocol GameSettingsUseCaseProtocol: Sendable {
    /// Returns only the game settings of the music service the user signed in with.
    /// The view model adds them to its `GameStarterViewData` and hands them to the game.
    func execute() async throws -> GameStarterViewData.GameSettings
}

/// Request sent to the Settings repository: each music service has its own settings.
struct GameSettingsRequest: SettingsRequestProtocol {
    let provider: MusicProvider
}

/// Reads the game settings when Play is tapped, so the game starts with the ones the user saved last,
/// even when they changed them in Settings after this screen loaded.
struct GameSettingsUseCase: GameSettingsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveSettingsRepository()
    }

    func execute() async throws -> GameStarterViewData.GameSettings {
        let response = try await repository.fetch(GameSettingsRequest(provider: provider))
        let levels = await repository.bingoLevels()
        let level = levels.first { $0.level == response.bingoLevel } ?? levels.first
        return Self.settings(from: response, level: level)
    }
}

private extension GameSettingsUseCase {
    typealias Settings = GameStarterViewData.GameSettings
    typealias Category = GameStarterViewData.BingoCategory

    /// Maps SettingsResponseProtocol and the saved Bingo level of the repository into the data the view model adds
    /// to its ViewData.
    static func settings(
        from response: any SettingsResponseProtocol,
        level: (any SettingsBingoLevelResponseProtocol)?
    ) -> Settings {
        Settings(
            playback: response.playbackMode == .fullSong ? .fullSong : .clip,
            clipSeconds: response.clipSeconds,
            clipStart: response.clipStart == .beginning ? .beginning : .random,
            mode: response.gameMode == .bingo ? .bingo : .classic,
            bingoLevelTitle: level.map { localized($0.titleKey) } ?? "",
            bingoCategories: level?.categories.map { category in
                Category(color: color(category.category), title: localized(category.titleKey))
            } ?? []
        )
    }

    /// The repository gives the keys of the names; the app's strings hold them.
    static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    static func color(_ category: SettingsBingoCategory) -> GameStarterViewData.BingoColor {
        switch category {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
