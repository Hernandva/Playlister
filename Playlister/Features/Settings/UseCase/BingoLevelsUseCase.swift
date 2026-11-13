import Foundation
import PlaylisterData

protocol BingoLevelsUseCaseProtocol: Sendable {
    /// Returns only the Bingo levels with their categories, names already localised.
    /// The view model adds them to its `SettingsViewData`.
    func execute() async -> [SettingsViewData.BingoLevel]
}

/// Reads the Bingo levels and their categories through the Settings repository public API.
struct BingoLevelsUseCase: BingoLevelsUseCaseProtocol {
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute() async -> [SettingsViewData.BingoLevel] {
        await repository.bingoLevels().map(Self.level)
    }
}

private extension BingoLevelsUseCase {
    /// Maps a level of the repository into the data the view model adds to its ViewData.
    static func level(_ response: any SettingsBingoLevelResponseProtocol) -> SettingsViewData.BingoLevel {
        SettingsViewData.BingoLevel(
            id: response.level.rawValue,
            title: String(localized: String.LocalizationValue(response.titleKey)),
            categories: response.categories.map { category in
                SettingsViewData.BingoCategory(
                    color: Self.color(category.category),
                    title: String(localized: String.LocalizationValue(category.titleKey))
                )
            }
        )
    }

    static func color(_ category: SettingsBingoCategory) -> SettingsViewData.BingoColor {
        switch category {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
