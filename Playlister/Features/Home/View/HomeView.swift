import PlaylisterUI
import SwiftUI

/// Home without a session: the spinning vinyl, the app name and the Spotify / Apple Music sign-in buttons.
struct HomeView: View {
    /// Keeps the column readable on iPad.
    private static let maxContentWidth: CGFloat = 480

    @State private var viewModel: HomeViewModel

    init(dependencies: HomeDependencies) {
        _viewModel = State(initialValue: dependencies.makeViewModel())
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
            Button {
                viewModel.signIn(with: .spotify)
            } label: {
                // Placeholder symbol: replace it with the logo from Spotify's brand kit.
                Label("home.signIn.spotify", systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(DSButtonStyle(style: .spotify))

            Button {
                viewModel.signIn(with: .appleMusic)
            } label: {
                // Placeholder symbol: replace it with the logo from Apple Music's brand kit.
                Label("home.signIn.appleMusic", systemImage: "music.note")
            }
            .buttonStyle(DSButtonStyle(style: .appleMusic))

            if case .failed(let message) = viewModel.state {
                DSText(message, style: .footnote, color: DSColor.destructive)
                    .multilineTextAlignment(.center)
            }

            DSText(style: .footnote)
                .localized("home.signIn.footnote")
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.space2)
                .padding(.top, DSSpacing.space2)
        }
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
