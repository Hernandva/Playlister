import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case authorizationLoaded
        case failed(String)
    }

    /// Music services the player can sign in with.
    enum Provider: Hashable, Identifiable, Sendable {
        case spotify
        case appleMusic

        var id: Self { self }

        /// Brand name of the service. Brand names are not translated.
        var displayName: String {
            switch self {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            }
        }
    }

    private(set) var state: State = .idle
    /// The service whose settings sheet is shown, or `nil` when the sheet is closed.
    var settingsSheetProvider: Provider?
    /// Data of the screen. Each use case result updates only its own field.
    private var viewData: HomeViewData
    private let authorizationUseCase: any AuthorizationUseCaseProtocol
    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
        self.viewData = HomeViewData()
        self.authorizationUseCase = dependencies.resolveAuthorizationUseCase()
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
        if viewData.authorization(for: provider) == .authorized {
            // Already authorised: continuing with the provider is not wired yet.
        } else {
            settingsSheetProvider = provider
        }
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
