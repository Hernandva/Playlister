import Foundation

/// Display-ready data of Game. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct GameViewData: Equatable, Sendable {
    /// The playlist the game is played with, chosen in ProviderStarter.
    struct Playlist: Equatable, Sendable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        /// `nil` when it was chosen in the selector, which does not read the songs.
        let songCount: Int?
        let covers: [URL]
    }

    /// Data returned by `GameUseCase`. Rename it after what it holds and add one type and one field
    /// per use case, with the properties the view needs.
    struct Content: Equatable, Sendable {}

    /// Known before anything loads: it comes from ProviderStarter.
    var playlist: Playlist
    /// Result of `GameUseCase`, or `nil` until it loads.
    var content: Content?
}
