import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = SettingsViewData()

    private let useCase: any SettingsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: SettingsDependencies) {
        self.useCase = dependencies.resolveUseCase()
    }

    func load() async {
        state = .loading
        do {
            viewData.content = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
