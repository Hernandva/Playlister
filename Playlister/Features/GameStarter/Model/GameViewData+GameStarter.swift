import Foundation

/// Hands the settings read by GameStarter to the Game feature, which has its own types.
/// `GameStarterCoordinator` uses it when it opens the game.
extension GameViewData.Settings {
    init(_ settings: GameStarterViewData.GameSettings) {
        self.init(
            playback: settings.playback == .fullSong ? .fullSong : .clip,
            clipSeconds: settings.clipSeconds,
            clipStart: settings.clipStart == .beginning ? .beginning : .random,
            mode: settings.mode == .bingo ? .bingo : .classic,
            bingoLevel: settings.bingoLevel == .expert ? .expert : .beginner,
            bingoCategories: Set(settings.bingoCategories.map(Self.category))
        )
    }

    private static func category(_ category: GameStarterViewData.BingoCategory) -> GameViewData.BingoCategory {
        switch category {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
