import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case authorizationLoaded
        case providerStartedLoaded
        case failed(String)
    }

    /// Music services the player can sign in with.
    enum Provider: Hashable, Identifiable, Sendable {
        case spotify
        case appleMusic
        case free

        var id: Self { self }

        /// Name of the service. Brand names are not translated; free mode is.
        var displayName: String {
            switch self {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            case .free: String(localized: "provider.free")
            }
        }
    }

    /// A failed login, shown in a bottom sheet.
    struct LoginErrorSheet: Identifiable, Equatable {
        let provider: Provider
        let failure: HomeViewData.LoginFailure

        var id: Provider { provider }
    }

    private(set) var state: State = .idle
    /// The service whose settings sheet is shown, or `nil` when the sheet is closed.
    var settingsSheetProvider: Provider?
    /// The failed login shown in the error sheet, or `nil` when the sheet is closed.
    var loginErrorSheet: LoginErrorSheet?
    /// The service being signed in with, or `nil` when no login is running.
    private(set) var startingProvider: Provider?
    /// Data of the screen. Each use case result updates only its own field.
    private var viewData: HomeViewData
    private let authorizationUseCase: any AuthorizationUseCaseProtocol
    private let startProviderUseCase: any StartProviderUseCaseProtocol
    private let coordinator: (any HomeCoordinatorProtocol)?
    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
        self.viewData = HomeViewData()
        self.authorizationUseCase = dependencies.resolveAuthorizationUseCase()
        self.startProviderUseCase = dependencies.resolveStartProviderUseCase()
        self.coordinator = dependencies.resolveCoordinator()
    }

    /// Text of the sign-in button of `provider`: "Continue with…" once authorised, "Allow access to…" otherwise.
    func signInTitle(for provider: Provider) -> String {
        let name = provider.displayName
        if viewData.authorization(for: provider) == .authorized {
            return String(localized: "home.signIn.continue \(name)")
        }
        return String(localized: "home.signIn.allow \(name)")
    }

    /// Called when a sign-in button is tapped.
    /// When `provider` is not authorised, opens the sheet that leads to the app's settings,
    /// because iOS does not show the permission prompt again once the user answered it.
    func didTapSignIn(with provider: Provider) {
        guard startingProvider == nil else { return }
        if viewData.authorization(for: provider) == .authorized {
            Task { await startProvider(provider) }
        } else {
            settingsSheetProvider = provider
        }
    }

    /// Signs in with `provider`: opens its screen on success, shows the error sheet otherwise.
    func startProvider(_ provider: Provider) async {
        startingProvider = provider
        defer { startingProvider = nil }
        state = .loading
        do {
            try await startProviderUseCase.execute(provider: provider)
            state = .providerStartedLoaded
            coordinator?.openProvider(provider)
        } catch let failure as HomeViewData.LoginFailure {
            state = .providerStartedLoaded
            loginErrorSheet = LoginErrorSheet(provider: provider, failure: failure)
        } catch {
            state = .providerStartedLoaded
            loginErrorSheet = LoginErrorSheet(provider: provider, failure: .unavailable)
        }
    }

    /// Title of the error sheet of a failed login.
    func loginErrorTitle(for sheet: LoginErrorSheet) -> String {
        String(localized: "home.loginError.title \(sheet.provider.displayName)")
    }

    /// Explanation of the error sheet of a failed login.
    func loginErrorMessage(for sheet: LoginErrorSheet) -> String {
        let name = sheet.provider.displayName
        switch sheet.failure {
        case .notAuthorized:
            return String(localized: "home.loginError.notAuthorized \(name)")
        case .subscriptionRequired:
            return String(localized: "home.loginError.subscriptionRequired \(name)")
        case .unavailable:
            return String(localized: "home.loginError.unavailable \(name)")
        }
    }

    func dismissLoginErrorSheet() {
        loginErrorSheet = nil
    }

    /// Title of the settings sheet of `provider`.
    func settingsSheetTitle(for provider: Provider) -> String {
        String(localized: "home.settingsSheet.title \(provider.displayName)")
    }

    /// Explanation of the settings sheet of `provider`.
    func settingsSheetMessage(for provider: Provider) -> String {
        String(localized: "home.settingsSheet.message \(provider.displayName)")
    }

    func dismissSettingsSheet() {
        settingsSheetProvider = nil
    }

    /// Signs in with every music service; leaves `loading` when the use case finishes.
    func load() async {
        state = .loading
        do {
            viewData.authorizations = try await authorizationUseCase.execute()
            state = .authorizationLoaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
