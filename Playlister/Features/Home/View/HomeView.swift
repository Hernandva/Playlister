import PlaylisterUI
import SwiftUI

/// Home without a session: the spinning vinyl, the app name and the Apple Music sign-in button.
struct HomeView: View {
    /// Keeps the column readable on iPad.
    private static let maxContentWidth: CGFloat = 480

    @State private var viewModel: HomeViewModel
    @Environment(\.openURL) private var openURL

    init(dependencies: HomeDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: DSSpacing.space6) {
                    Spacer(minLength: DSSpacing.space8)
                    hero
                    Spacer(minLength: DSSpacing.space8)
                    signIn
                }
                .padding(.horizontal, DSSpacing.space6)
                .padding(.top, DSSpacing.space4)
                .padding(.bottom, DSSpacing.space3)
                .frame(maxWidth: Self.maxContentWidth)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background { DSAuraBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task { await viewModel.load() }
        .sheet(item: $viewModel.settingsSheetProvider) { provider in
            settingsSheet(for: provider)
        }
        .sheet(item: $viewModel.loginErrorSheet) { sheet in
            loginErrorSheet(for: sheet)
        }
    }

    private var hero: some View {
        VStack(spacing: DSSpacing.space6) {
            DSVinyl(phase: .playing, diameter: 200)
                .accessibilityHidden(true)
            VStack(spacing: DSSpacing.space3) {
                DSText(style: .hero)
                    .localized("home.title")
                    .accessibilityAddTraits(.isHeader)
                DSText(style: .body, color: DSColor.textSecondary)
                    .localized("home.tagline")
            }
            .multilineTextAlignment(.center)
        }
    }

    private var signIn: some View {
        VStack(spacing: DSSpacing.space3) {
            switch viewModel.state {
            case .idle, .loading:
                loading
            case .authorizationLoaded, .providerStartedLoaded, .failed:
                signInButtons
            }
            DSText(style: .footnote)
                .localized("home.signIn.footnote")
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.space2)
                .padding(.top, DSSpacing.space2)
        }
    }

    /// Shown while the authorisations load, in place of the sign-in buttons.
    /// Takes the height of the sign-in button so the layout does not jump when it appears.
    private var loading: some View {
        VStack(spacing: DSSpacing.space3) {
            ProgressView()
                .tint(DSColor.textSecondary)
            DSText(style: .footnote, color: DSColor.textSecondary)
                .localized("home.loading")
        }
        .frame(maxWidth: .infinity, minHeight: DSButtonStyle.capsuleHeight)
        .accessibilityElement(children: .combine)
    }

    /// Bottom sheet shown when `provider` has no authorisation: leads to the app's page in Settings,
    /// where the user can allow access (for Apple Music, "Media & Apple Music").
    private func settingsSheet(for provider: HomeViewModel.Provider) -> some View {
        DSBottomSheet(
            title: viewModel.settingsSheetTitle(for: provider),
            message: viewModel.settingsSheetMessage(for: provider),
            primaryAction: .init(String(localized: "home.settingsSheet.openSettings")) {
                viewModel.dismissSettingsSheet()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            },
            secondaryAction: .init(String(localized: "home.settingsSheet.notNow"), style: .plain) {
                viewModel.dismissSettingsSheet()
            }
        )
    }

    /// Bottom sheet shown when signing in with a service fails: the error and a button that closes it.
    private func loginErrorSheet(for sheet: HomeViewModel.LoginErrorSheet) -> some View {
        DSBottomSheet(
            title: viewModel.loginErrorTitle(for: sheet),
            message: viewModel.loginErrorMessage(for: sheet),
            primaryAction: .init(String(localized: "home.loginError.accept")) {
                viewModel.dismissLoginErrorSheet()
            }
        )
    }

    private var signInButtons: some View {
        // Only Apple Music signs in from Home for now; the Spotify provider stays in the view model.
        VStack(spacing: DSSpacing.space3) {
            Button {
                viewModel.didTapSignIn(with: .appleMusic)
            } label: {
                // Placeholder symbol: replace it with the logo from Apple Music's brand kit.
                Label(viewModel.signInTitle(for: .appleMusic), systemImage: "music.note")
            }
            .buttonStyle(DSButtonStyle(style: .appleMusic))
        }
        .disabled(viewModel.startingProvider != nil)
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
