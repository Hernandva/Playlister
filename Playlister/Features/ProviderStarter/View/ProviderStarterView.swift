import PlaylisterData
import PlaylisterUI
import SwiftUI

/// Home with a session: the connected service, the playlist card and the Play button.
/// The card has the same format with and without a playlist: with none it invites the user to choose one
/// («Elegir lista») and Play is hidden; with one it shows it and «Cambiar lista» opens the selector.
struct ProviderStarterView: View {
    /// Keeps the column readable on iPad.
    private static let maxContentWidth: CGFloat = 480
    private static let coverSide: CGFloat = 112
    private static let playDiameter: CGFloat = 132

    @State private var viewModel: ProviderStarterViewModel
    @Environment(\.dismiss) private var dismiss

    /// Receives only the container and resolves the view model from it.
    init(dependencies: ProviderStarterDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.space6) {
                    header
                    greeting
                    selectedPlaylist
                    Spacer(minLength: DSSpacing.space6)
                    if viewModel.selectedPlaylist != nil {
                        play
                        Spacer(minLength: DSSpacing.space6)
                    }
                }
                .padding(.horizontal, DSSpacing.space4)
                .padding(.top, DSSpacing.space2)
                .padding(.bottom, DSSpacing.space3)
                .frame(maxWidth: Self.maxContentWidth)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background { DSAuraBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .preferredColorScheme(.dark)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.isChangeProviderSheetPresented, onDismiss: returnHomeIfRequested) {
            changeProviderSheet
        }
    }

    /// Goes back to Home once the sheet has closed, so both animations do not run at the same time.
    private func returnHomeIfRequested() {
        if viewModel.wantsToReturnHome {
            dismiss()
        }
    }

    /// Bottom sheet opened from the badge: back to Home to pick another music service, or stay.
    private var changeProviderSheet: some View {
        DSBottomSheet(
            title: viewModel.changeProviderSheetTitle,
            message: viewModel.changeProviderSheetMessage,
            primaryAction: .init(String(localized: "providerStarter.changeProvider.returnHome")) {
                viewModel.didChooseReturnHome()
            },
            secondaryAction: .init(String(localized: "providerStarter.changeProvider.stay"), style: .plain) {
                viewModel.dismissChangeProviderSheet()
            }
        )
    }

    private var header: some View {
        // Settings on the leading side and the badge on the trailing side, like the chip in Game's header.
        HStack {
            NavigationLink(value: ProviderStarterCoordinator.Route.settings) {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(DSIconButtonStyle(diameter: DSSpacing.tapMin))
            .accessibilityLabel(String(localized: "providerStarter.settings"))
            Spacer()
            DSStatusBadge(viewModel.connectedTitle, style: badgeStyle) {
                viewModel.didTapProviderBadge()
            }
            .accessibilityHint(String(localized: "providerStarter.changeProvider.hint"))
        }
    }

    private var badgeStyle: DSStatusBadge.Style {
        switch viewModel.provider {
        case .spotify: .spotify
        case .appleMusic: .appleMusic
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space1) {
            DSText(style: .body, color: DSColor.textSecondary)
                .localized("providerStarter.greeting")
            DSText(style: .largeTitle)
                .localized("providerStarter.title")
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder private var selectedPlaylist: some View {
        if viewModel.needsPlaylist {
            selectPlaylistCard
        } else {
            VStack(alignment: .leading, spacing: DSSpacing.space2) {
                DSSectionHeader()
                    .localized(viewModel.isShowingSelection
                        ? "providerStarter.selectedPlaylist.header.selected"
                        : "providerStarter.selectedPlaylist.header.last")
                selectedPlaylistContent
            }
        }
    }

    /// Shown while no playlist has been chosen with this music service: Play stays disabled until there is one.
    private var selectPlaylistCard: some View {
        playlistCard(
            covers: [],
            title: String(localized: "providerStarter.selectPlaylist.title"),
            subtitle: String(localized: "providerStarter.selectPlaylist.message"),
            action: String(localized: "providerStarter.selectPlaylist.action")
        )
    }

    @ViewBuilder private var selectedPlaylistContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            DSCard {
                ProgressView()
                    .tint(DSColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Self.coverSide)
            }
        case .loaded:
            if let playlist = viewModel.selectedPlaylist {
                playlistCard(
                    covers: playlist.covers,
                    title: playlist.name,
                    subtitle: viewModel.songCountText(for: playlist),
                    action: String(localized: "providerStarter.changePlaylist")
                )
            }
        case .failed(let message):
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.space3) {
                    DSText(message, style: .footnote, color: DSColor.destructive)
                    DSButton(style: .plain) {
                        Task { await viewModel.load() }
                    }
                    .localized("providerStarter.retry")
                }
                .frame(maxWidth: .infinity, minHeight: Self.coverSide, alignment: .leading)
            }
        }
    }

    /// The playlist card, the same with and without a playlist: the cover mosaic, a title, a subtitle and a button
    /// that opens the selector («Elegir lista» or «Cambiar lista»). Strings are passed already localised.
    private func playlistCard(covers: [URL], title: String, subtitle: String?, action: String) -> some View {
        DSCard {
            HStack(spacing: DSSpacing.space4) {
                DSCoverMosaic(covers: covers)
                    .frame(width: Self.coverSide, height: Self.coverSide)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusCard, style: .continuous))
                    .dsShadow(.card)
                VStack(alignment: .leading, spacing: DSSpacing.space2) {
                    DSText(title, style: .headline)
                        .lineLimit(2)
                    if let subtitle {
                        DSText(subtitle, style: .subheadline)
                    }
                    NavigationLink(value: ProviderStarterCoordinator.Route.playlistSelector) {
                        Text(action)
                    }
                    .buttonStyle(DSButtonStyle(style: .plain))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Self.coverSide)
        }
    }

    private var play: some View {
        VStack(spacing: DSSpacing.space3) {
            DSIconButton(systemImage: "play.fill", style: .play, diameter: Self.playDiameter) {
                Task { await viewModel.didTapPlay() }
            }
            .localized("providerStarter.play.accessibility")
            .disabled(viewModel.isStartingGame)
            DSText(style: .sectionTitle)
                .localized("providerStarter.play")
                .accessibilityHidden(true)
            if let message = viewModel.playErrorMessage {
                DSText(message, style: .footnote, color: DSColor.destructive)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProviderStarterCoordinator(provider: .appleMusic, signOut: {}, navigate: { _ in }).start()
    }
}
