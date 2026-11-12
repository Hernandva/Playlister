import Foundation
import Networking

protocol SettingsUseCaseProtocol: Sendable {
    /// Returns only the data of the response. The view model adds it to its `SettingsViewData`.
    func execute() async throws -> SettingsViewData.Content
}

/// Request sent to the Settings repository. Add the fields its public request protocol declares.
struct SettingsRequest: SettingsRequestProtocol {}

/// Business logic of Settings: calls the Settings repository public API and returns only the data of its
/// response, mapped out of the Networking types.
struct SettingsUseCase: SettingsUseCaseProtocol {
    /// One of the service names declared in `SettingsRepository.configuration.serviceNames`.
    private let serviceName = ""

    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `SettingsDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> SettingsViewData.Content {
        let response = try await repository.fetch(SettingsRequest(), serviceName: serviceName)
        return Self.content(from: response)
    }
}

private extension SettingsUseCase {
    /// Maps the fields of SettingsResponseProtocol into the data the view model adds to its ViewData.
    static func content(from response: any SettingsResponseProtocol) -> SettingsViewData.Content {
        SettingsViewData.Content()
    }
}
