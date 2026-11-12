import Foundation
import Observation

/// Display-ready data of Home: the authorisation state of every music service.
/// It is a shared object held by `HomeDependencies`: the use case writes it and the view model reads it.
@MainActor
@Observable
final class HomeViewData {
    /// Result of asking a music service for access.
    enum Authorization: Equatable, Sendable {
        /// The service has not been asked yet.
        case notDetermined
        case authorized
        /// The user said no, now or earlier. It can only be changed in Settings.
        case denied
        /// Screen Time or a device profile blocks access to the service.
        case restricted
        /// The service cannot be connected yet.
        case unavailable
    }

    /// Authorisation state of one music service.
    struct ProviderAuthorization: Equatable, Sendable, Identifiable {
        let provider: HomeViewModel.Provider
        let authorization: Authorization

        var id: HomeViewModel.Provider { provider }
    }

    /// One entry per music service that has been asked, in the order they were asked.
    private(set) var authorizations: [ProviderAuthorization] = []

    /// Authorisation of `provider`, or `.notDetermined` when it has not been asked yet.
    func authorization(for provider: HomeViewModel.Provider) -> Authorization {
        authorizations.first { $0.provider == provider }?.authorization ?? .notDetermined
    }

    /// Stores the result of `provider`, replacing the previous one.
    func update(_ authorization: Authorization, for provider: HomeViewModel.Provider) {
        let entry = ProviderAuthorization(provider: provider, authorization: authorization)
        if let index = authorizations.firstIndex(where: { $0.provider == provider }) {
            authorizations[index] = entry
        } else {
            authorizations.append(entry)
        }
    }
}
