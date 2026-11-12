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

/// Difficulty of the Bingo mode. It changes what each category asks.
public enum SettingsBingoLevel: String, Codable, CodingKeyRepresentable, Sendable, CaseIterable {
    case beginner
    case expert
}

/// The five Bingo categories, by their color.
public enum SettingsBingoCategory: String, Codable, Sendable, CaseIterable {
    case pink
    case yellow
    case cyan
    case green
    case orange
}

/// The game settings, as the app stores and shows them.
public protocol GameSettingsProtocol: Sendable {
    var playbackMode: SettingsPlaybackMode { get }
    /// Length of a clip, in seconds (5 to 60, in steps of 5).
    var clipSeconds: Int { get }
    var clipStart: SettingsClipStart { get }
    var gameMode: SettingsGameMode { get }
    var bingoLevel: SettingsBingoLevel { get }
    /// Bingo categories the user turned off, per level. A level that is missing has every category on.
    var disabledBingoCategories: [SettingsBingoLevel: Set<SettingsBingoCategory>] { get }
}

/// Public data the Settings repository returns to the app: the saved settings, or the default ones.
public protocol SettingsResponseProtocol: GameSettingsProtocol {}
