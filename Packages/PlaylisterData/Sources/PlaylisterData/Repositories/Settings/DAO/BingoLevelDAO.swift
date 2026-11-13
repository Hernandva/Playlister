import Foundation

/// A category of a Bingo level. Internal to PlaylisterData: the app only sees
/// `SettingsBingoCategoryResponseProtocol`.
struct BingoCategoryDAO: Sendable, Equatable, SettingsBingoCategoryResponseProtocol {
    let category: SettingsBingoCategory
    let titleKey: String
}

/// A Bingo level with its categories. Internal to PlaylisterData: the app only sees
/// `SettingsBingoLevelResponseProtocol`.
struct BingoLevelDAO: Sendable, SettingsBingoLevelResponseProtocol {
    let level: SettingsBingoLevel
    let titleKey: String
    let categoryDAOs: [BingoCategoryDAO]

    var categories: [any SettingsBingoCategoryResponseProtocol] { categoryDAOs }

    /// Every level has the five categories, in order; only the names change, so the keys follow
    /// `bingo.level.<level>` and `bingo.category.<color>.<level>`.
    init(level: SettingsBingoLevel) {
        self.level = level
        self.titleKey = "bingo.level.\(level.rawValue)"
        self.categoryDAOs = SettingsBingoCategory.allCases.map { category in
            BingoCategoryDAO(category: category, titleKey: "bingo.category.\(category.rawValue).\(level.rawValue)")
        }
    }
}
