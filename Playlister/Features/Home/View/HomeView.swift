import PlaylisterUI
import SwiftUI

/// Home without a session: the spinning vinyl, the app name and the Spotify / Apple Music sign-in buttons.
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
            case .authorizationLoaded, .failed:
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
    /// Takes the height of the two buttons so the layout does not jump when they appear.
    private var loading: some View {
        VStack(spacing: DSSpacing.space3) {
            ProgressView()
                .tint(DSColor.textSecondary)
            DSText(style: .footnote, color: DSColor.textSecondary)
                .localized("home.loading")
        }
        .frame(maxWidth: .infinity, minHeight: DSButtonStyle.capsuleHeight * 2 + DSSpacing.space3)
        .accessibilityElement(children: .combine)
    }

    /// Bottom sheet shown when `provider` has no authorisation: leads to the app's page in Settings,
    /// where the user can allow access (for Apple Music, "Media & Apple Music").
    private func settingsSheet(for provider: HomeViewModel.Provider) -> some View {
        VStack(spacing: DSSpacing.space4) {
            DSText(viewModel.settingsSheetTitle(for: provider), style: .title)
                .accessibilityAddTraits(.isHeader)
            DSText(viewModel.settingsSheetMessage(for: provider), style: .body, color: DSColor.textSecondary)
            VStack(spacing: DSSpacing.space2) {
                DSButton(style: .primary) {
                    viewModel.dismissSettingsSheet()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .localized("home.settingsSheet.openSettings")
                DSButton(style: .plain) {
                    viewModel.dismissSettingsSheet()
                }
                .localized("home.settingsSheet.notNow")
            }
            .padding(.top, DSSpacing.space2)
        }
        .multilineTextAlignment(.center)
        .padding(DSSpacing.space6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { DSAuraBackground() }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var signInButtons: some View {
        VStack(spacing: DSSpacing.space3) {
            Button {
                viewModel.didTapSignIn(with: .spotify)
            } label: {
                // Placeholder symbol: replace it with the logo from Spotify's brand kit.
                Label(viewModel.signInTitle(for: .spotify), systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(DSButtonStyle(style: .spotify))

            Button {
                viewModel.didTapSignIn(with: .appleMusic)
            } label: {
                // Placeholder symbol: replace it with the logo from Apple Music's brand kit.
                Label(viewModel.signInTitle(for: .appleMusic), systemImage: "music.note")
            }
            .buttonStyle(DSButtonStyle(style: .appleMusic))
        }
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
