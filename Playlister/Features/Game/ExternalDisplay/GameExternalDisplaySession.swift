import Observation

/// Bridge between the game on the iPhone and the external display (a TV through AirPlay or a cable).
///
/// UIKit creates the external display's scene on its own, so it cannot receive the game's dependencies: it reads
/// this shared session instead. The game that is playing presents its view model here, and the display mirrors it
/// with `GameExternalDisplayView`; the display tells the session when it connects, so the iPhone can show it.
@MainActor
@Observable
final class GameExternalDisplaySession {
    static let shared = GameExternalDisplaySession()

    /// The game being played, shown on the external display, or `nil` outside a game.
    private(set) var game: GameViewModel?
    /// External displays connected: one in practice, counted so two connections and one disconnection stay right.
    private var connectedDisplays = 0

    /// `true` while an external display shows the app.
    var isDisplayConnected: Bool {
        connectedDisplays > 0
    }

    /// The game started: the external display shows it.
    func present(_ game: GameViewModel) {
        self.game = game
    }

    /// The game ended. Only the game being shown can take itself off, so an old game that stops late does not hide
    /// a new one.
    func dismiss(_ game: GameViewModel) {
        guard self.game === game else { return }
        self.game = nil
    }

    func displayDidConnect() {
        connectedDisplays += 1
    }

    func displayDidDisconnect() {
        connectedDisplays = max(0, connectedDisplays - 1)
    }
}
