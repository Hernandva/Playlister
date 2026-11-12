import Foundation

/// Display-ready data of Home. The view model owns it and updates each field on its own,
/// so storing new authorisations never erases the rest of the data.
struct HomeViewData: Equatable, Sendable {
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
    var authorizations: [ProviderAuthorization] = []

    /// Authorisation of `provider`, or `.notDetermined` when it has not been asked yet.
    func authorization(for provider: HomeViewModel.Provider) -> Authorization {
        authorizations.first { $0.provider == provider }?.authorization ?? .notDetermined
    }
}
