import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(HomeViewData)
        case failed(String)
    }

    private(set) var state: State = .idle

    private let useCase: any HomeUseCaseProtocol

    init(useCase: any HomeUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.execute())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
