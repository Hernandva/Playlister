import Foundation
@testable import PlaylisterData
import Testing

private struct FakeSettingsRequest: SettingsRequestProtocol {
    let provider: MusicProvider
}

struct SettingsRepositoryTests {
    private static let custom = GameSettingsDAO(
        playbackMode: .fullSong,
        clipSeconds: 45,
        clipStart: .beginning,
        gameMode: .bingo,
        bingoLevel: .expert
    )

    /// A repository on its own empty `UserDefaults` suite, so tests never share data.
    private static func makeRepository(suiteName: String = "SettingsRepositoryTests.\(UUID().uuidString)")
        -> SettingsRepository {
        SettingsRepository(storage: SettingsUserDefaultsStorage(suiteName: suiteName))
    }

    @Test func returnsTheDefaultsWhenNoneWereSaved() async throws {
        let response = try await Self.makeRepository().fetch(FakeSettingsRequest(provider: .appleMusic))

        #expect(GameSettingsDAO(response) == GameSettingsDAO.defaults)
    }

    @Test func returnsTheSavedSettings() async throws {
        let repository = Self.makeRepository()

        try await repository.saveSettings(Self.custom, for: .appleMusic)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .appleMusic))

        #expect(GameSettingsDAO(response) == Self.custom)
    }

    @Test func keepsEachProviderSettingsApart() async throws {
        let repository = Self.makeRepository()

        try await repository.saveSettings(Self.custom, for: .appleMusic)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(GameSettingsDAO(response) == GameSettingsDAO.defaults)
    }

    @Test func fillsMissingFieldsWithTheDefaults() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"gameMode":"bingo","clipSeconds":30}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.gameMode == .bingo)
        #expect(response.clipSeconds == 30)
        #expect(response.playbackMode == GameSettingsDAO.defaults.playbackMode)
        #expect(response.bingoLevel == GameSettingsDAO.defaults.bingoLevel)
    }

    @Test func ignoresTheRemovedBingoCategoriesField() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"bingoLevel":"expert","disabledBingoCategories":{"expert":["pink"]}}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.bingoLevel == .expert)
    }

    @Test func offersEveryBingoLevelInOrder() async {
        let levels = await Self.makeRepository().bingoLevels()

        #expect(levels.map(\.level) == SettingsBingoLevel.allCases)
    }

    @Test func everyBingoLevelHasTheFiveCategoriesWithItsOwnNames() async {
        let levels = await Self.makeRepository().bingoLevels()

        for level in levels {
            #expect(level.titleKey == "bingo.level.\(level.level.rawValue)")
            #expect(level.categories.map(\.category) == SettingsBingoCategory.allCases)
            #expect(level.categories.map(\.titleKey) == SettingsBingoCategory.allCases.map {
                "bingo.category.\($0.rawValue).\(level.level.rawValue)"
            })
        }
    }

    @Test func readsAnUnknownBingoLevelAsTheDefaultAndKeepsTheRest() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"bingoLevel":"master","gameMode":"bingo","clipSeconds":45}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.bingoLevel == GameSettingsDAO.defaults.bingoLevel)
        #expect(response.gameMode == .bingo)
        #expect(response.clipSeconds == 45)
    }
}
