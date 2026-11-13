import Foundation
import PlaylisterData

protocol GameSettingsUseCaseProtocol: Sendable {
    /// Returns only the game settings of the music service the user signed in with.
    /// The view model adds them to its `ProviderStarterViewData` and hands them to the game.
    func execute() async throws -> ProviderStarterViewData.GameSettings
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
    /// `ProviderStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ProviderStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveSettingsRepository()
    }

    func execute() async throws -> ProviderStarterViewData.GameSettings {
        let response = try await repository.fetch(GameSettingsRequest(provider: provider))
        return Self.settings(from: response)
    }
}

private extension GameSettingsUseCase {
    typealias Settings = ProviderStarterViewData.GameSettings

    /// Maps SettingsResponseProtocol into the data the view model adds to its ViewData.
    static func settings(from response: any SettingsResponseProtocol) -> Settings {
        let disabled = response.disabledBingoCategories[response.bingoLevel] ?? []
        return Settings(
            playback: response.playbackMode == .fullSong ? .fullSong : .clip,
            clipSeconds: response.clipSeconds,
            clipStart: response.clipStart == .beginning ? .beginning : .random,
            mode: response.gameMode == .bingo ? .bingo : .classic,
            bingoLevel: response.bingoLevel == .expert ? .expert : .beginner,
            bingoCategories: Set(
                SettingsBingoCategory.allCases
                    .filter { !disabled.contains($0) }
                    .map(category)
            )
        )
    }

    static func category(_ category: SettingsBingoCategory) -> ProviderStarterViewData.BingoCategory {
        switch category {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
