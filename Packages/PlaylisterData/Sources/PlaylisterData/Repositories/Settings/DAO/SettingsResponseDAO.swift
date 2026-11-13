import Foundation

/// Stored format of the game settings. Internal to PlaylisterData: the app only sees SettingsResponseProtocol.
struct GameSettingsDAO: Codable, Sendable, Equatable, SettingsResponseProtocol {
    /// Settings of a first launch: 30-second clips from a random point, classic mode, beginner Bingo level.
    static let defaults = GameSettingsDAO(
        playbackMode: .clip,
        clipSeconds: 30,
        clipStart: .random,
        gameMode: .classic,
        bingoLevel: .beginner
    )

    let playbackMode: SettingsPlaybackMode
    let clipSeconds: Int
    let clipStart: SettingsClipStart
    let gameMode: SettingsGameMode
    let bingoLevel: SettingsBingoLevel

    init(
        playbackMode: SettingsPlaybackMode,
        clipSeconds: Int,
        clipStart: SettingsClipStart,
        gameMode: SettingsGameMode,
        bingoLevel: SettingsBingoLevel
    ) {
        self.playbackMode = playbackMode
        self.clipSeconds = clipSeconds
        self.clipStart = clipStart
        self.gameMode = gameMode
        self.bingoLevel = bingoLevel
    }

    init(_ settings: some GameSettingsProtocol) {
        self.init(
            playbackMode: settings.playbackMode,
            clipSeconds: settings.clipSeconds,
            clipStart: settings.clipStart,
            gameMode: settings.gameMode,
            bingoLevel: settings.bingoLevel
        )
    }

    /// A field that is missing, e.g. one added in a later version, takes its default value,
    /// so the rest of the saved settings is kept. Fields no longer used, such as the old
    /// `disabledBingoCategories`, are ignored.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults
        self.init(
            playbackMode: try container.decodeIfPresent(SettingsPlaybackMode.self, forKey: .playbackMode)
                ?? defaults.playbackMode,
            clipSeconds: try container.decodeIfPresent(Int.self, forKey: .clipSeconds) ?? defaults.clipSeconds,
            clipStart: try container.decodeIfPresent(SettingsClipStart.self, forKey: .clipStart) ?? defaults.clipStart,
            gameMode: try container.decodeIfPresent(SettingsGameMode.self, forKey: .gameMode) ?? defaults.gameMode,
            // A level this version does not know, e.g. saved by a newer one, reads as the default level
            // instead of losing every setting.
            bingoLevel: (try? container.decodeIfPresent(SettingsBingoLevel.self, forKey: .bingoLevel))
                ?? defaults.bingoLevel
        )
    }
}
