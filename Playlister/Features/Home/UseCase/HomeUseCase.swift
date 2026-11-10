import Foundation

protocol HomeUseCaseProtocol: Sendable {
    func execute() async throws -> HomeViewData
}

/// Business logic of Home.
/// When the feature needs remote data, inject a repository from Networking through
/// HomeDependencies and map its public response protocol into HomeViewData.
struct HomeUseCase: HomeUseCaseProtocol {
    func execute() async throws -> HomeViewData {
        HomeViewData()
    }
}
