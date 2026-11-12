import Foundation
@testable import Networking
import Testing

private struct FakeSettingsRequest: SettingsRequestProtocol {}

struct SettingsRepositoryTests {
    private static let custom = GameSettingsDAO(
        playbackMode: .fullSong,
        clipSeconds: 45,
        clipStart: .beginning,
        gameMode: .bingo,
        bingoLevel: .expert,
        disabledBingoCategories: [.expert: [.pink, .orange]]
    )

    /// A repository on its own empty `UserDefaults` suite, so tests never share data.
    private static func makeRepository(suiteName: String = "SettingsRepositoryTests.\(UUID().uuidString)")
        -> SettingsRepository {
        SettingsRepository(storage: SettingsUserDefaultsStorage(suiteName: suiteName))
    }

    @Test func returnsTheDefaultsWhenNoneWereSaved() async throws {
        let response = try await Self.makeRepository().fetch(FakeSettingsRequest())

        #expect(GameSettingsDAO(response) == GameSettingsDAO.defaults)
    }

    @Test func returnsTheSavedSettings() async throws {
        let repository = Self.makeRepository()

        try await repository.saveSettings(Self.custom)
        let response = try await repository.fetch(FakeSettingsRequest())

        #expect(GameSettingsDAO(response) == Self.custom)
    }

    @Test func fillsMissingFieldsWithTheDefaults() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"gameMode":"bingo","clipSeconds":30}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key)

        let response = try await Self.makeRepository(suiteName: suiteName).fetch(FakeSettingsRequest())

        #expect(response.gameMode == .bingo)
        #expect(response.clipSeconds == 30)
        #expect(response.playbackMode == GameSettingsDAO.defaults.playbackMode)
        #expect(response.disabledBingoCategories.isEmpty)
    }
}
