import Foundation

/// Stored format of the game settings. Internal to PlaylisterData: the app only sees SettingsResponseProtocol.
struct GameSettingsDAO: Codable, Sendable, Equatable, SettingsResponseProtocol {
    /// Settings of a first launch: 30-second clips from a random point, classic mode, every category on.
    static let defaults = GameSettingsDAO(
        playbackMode: .clip,
        clipSeconds: 30,
        clipStart: .random,
        gameMode: .classic,
        bingoLevel: .beginner,
        disabledBingoCategories: [:]
    )

    let playbackMode: SettingsPlaybackMode
    let clipSeconds: Int
    let clipStart: SettingsClipStart
    let gameMode: SettingsGameMode
    let bingoLevel: SettingsBingoLevel
    let disabledBingoCategories: [SettingsBingoLevel: Set<SettingsBingoCategory>]

    init(
        playbackMode: SettingsPlaybackMode,
        clipSeconds: Int,
        clipStart: SettingsClipStart,
        gameMode: SettingsGameMode,
        bingoLevel: SettingsBingoLevel,
        disabledBingoCategories: [SettingsBingoLevel: Set<SettingsBingoCategory>]
    ) {
        self.playbackMode = playbackMode
        self.clipSeconds = clipSeconds
        self.clipStart = clipStart
        self.gameMode = gameMode
        self.bingoLevel = bingoLevel
        self.disabledBingoCategories = disabledBingoCategories
    }

    init(_ settings: some GameSettingsProtocol) {
        self.init(
            playbackMode: settings.playbackMode,
            clipSeconds: settings.clipSeconds,
            clipStart: settings.clipStart,
            gameMode: settings.gameMode,
            bingoLevel: settings.bingoLevel,
            disabledBingoCategories: settings.disabledBingoCategories
        )
    }

    /// A field that is missing, e.g. one added in a later version, takes its default value,
    /// so the rest of the saved settings is kept.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults
        self.init(
            playbackMode: try container.decodeIfPresent(SettingsPlaybackMode.self, forKey: .playbackMode)
                ?? defaults.playbackMode,
            clipSeconds: try container.decodeIfPresent(Int.self, forKey: .clipSeconds) ?? defaults.clipSeconds,
            clipStart: try container.decodeIfPresent(SettingsClipStart.self, forKey: .clipStart) ?? defaults.clipStart,
            gameMode: try container.decodeIfPresent(SettingsGameMode.self, forKey: .gameMode) ?? defaults.gameMode,
            bingoLevel: try container.decodeIfPresent(SettingsBingoLevel.self, forKey: .bingoLevel)
                ?? defaults.bingoLevel,
            disabledBingoCategories: try container.decodeIfPresent(
                [SettingsBingoLevel: Set<SettingsBingoCategory>].self,
                forKey: .disabledBingoCategories
            ) ?? defaults.disabledBingoCategories
        )
    }
}
