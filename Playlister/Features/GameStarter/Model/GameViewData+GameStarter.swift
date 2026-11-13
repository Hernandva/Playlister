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
            bingoLevelTitle: settings.bingoLevelTitle,
            bingoCategories: settings.bingoCategories.map { category in
                GameViewData.BingoCategory(color: Self.color(category.color), title: category.title)
            }
        )
    }

    private static func color(_ color: GameStarterViewData.BingoColor) -> GameViewData.BingoColor {
        switch color {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
