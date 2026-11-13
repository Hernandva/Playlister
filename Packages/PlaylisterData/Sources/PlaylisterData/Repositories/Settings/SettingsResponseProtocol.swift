import Foundation

public enum SettingsError: Error, Equatable, Sendable {
    /// The settings could not be written to the local storage.
    case storageFailed
}

/// What each round plays of a song.
public enum SettingsPlaybackMode: String, Codable, Sendable, CaseIterable {
    /// The whole song, before it is revealed.
    case fullSong
    /// A clip of `GameSettingsProtocol.clipSeconds`.
    case clip
}

/// Where a clip starts in the song.
public enum SettingsClipStart: String, Codable, Sendable, CaseIterable {
    case beginning
    case random
}

public enum SettingsGameMode: String, Codable, Sendable, CaseIterable {
    /// One song after another: guess its data.
    case classic
    /// Musical bingo cards.
    case bingo
}

/// Difficulty of the Bingo mode. It changes what each category asks. A new level adds a case with a new raw value
/// and its entry in `BingoLevelsCatalog`; the raw values are what is stored, so existing ones never change.
public enum SettingsBingoLevel: String, Codable, Sendable, CaseIterable {
    case beginner
    case expert
}

/// The five Bingo categories, by their color. Every level has all five, in this order.
public enum SettingsBingoCategory: String, Sendable, CaseIterable {
    case pink
    case yellow
    case cyan
    case green
    case orange
}

/// One category of a Bingo level, returned by `SettingsRepositoryProtocol.bingoLevels()`.
public protocol SettingsBingoCategoryResponseProtocol: Sendable {
    var category: SettingsBingoCategory { get }
    /// Key of the category's name in this level in the app's strings, e.g. `bingo.category.pink.beginner`.
    var titleKey: String { get }
}

/// A Bingo level with its categories, returned by `SettingsRepositoryProtocol.bingoLevels()`.
public protocol SettingsBingoLevelResponseProtocol: Sendable {
    var level: SettingsBingoLevel { get }
    /// Key of the level's name in the app's strings, e.g. `bingo.level.beginner`.
    var titleKey: String { get }
    /// The five categories, in the order of `SettingsBingoCategory`.
    var categories: [any SettingsBingoCategoryResponseProtocol] { get }
}

/// The game settings, as the app stores and shows them.
public protocol GameSettingsProtocol: Sendable {
    var playbackMode: SettingsPlaybackMode { get }
    /// Length of a clip, in seconds (5 to 60, in steps of 5).
    var clipSeconds: Int { get }
    var clipStart: SettingsClipStart { get }
    var gameMode: SettingsGameMode { get }
    var bingoLevel: SettingsBingoLevel { get }
}

/// Public data the Settings repository returns to the app: the saved settings, or the default ones.
public protocol SettingsResponseProtocol: GameSettingsProtocol {}
