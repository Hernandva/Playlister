import Foundation

/// The Bingo levels the app offers, in the order Settings shows them. It ships with the app, so it is a local
/// source; it could move to a remote one without the features noticing.
enum BingoLevelsCatalog {
    /// One entry per level. Adding a level is a new `SettingsBingoLevel` case here, plus its strings in the app.
    static let levels: [BingoLevelDAO] = [
        BingoLevelDAO(level: .beginner),
        BingoLevelDAO(level: .expert)
    ]
}
