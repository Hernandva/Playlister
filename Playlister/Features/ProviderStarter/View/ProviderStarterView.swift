import PlaylisterData
import PlaylisterUI
import SwiftUI

/// Home with a session: the connected service, the last playlist, the Play button and «Choose another playlist».
/// With no playlist chosen yet, a card invites the user to choose one before playing.
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
                    play
                    Spacer(minLength: DSSpacing.space6)
                    if !viewModel.needsPlaylist {
                        choosePlaylist
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
        HStack {
            DSStatusBadge(viewModel.connectedTitle, style: badgeStyle) {
                viewModel.didTapProviderBadge()
            }
            .accessibilityHint(String(localized: "providerStarter.changeProvider.hint"))
            Spacer()
            NavigationLink(value: ProviderStarterCoordinator.Route.settings) {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(DSIconButtonStyle(diameter: DSSpacing.tapMin))
            .accessibilityLabel(String(localized: "providerStarter.settings"))
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
                DSCard {
                    selectedPlaylistContent
                        .frame(maxWidth: .infinity, minHeight: Self.coverSide, alignment: .leading)
                }
            }
        }
    }

    /// Shown while no playlist has been chosen with this music service: Play stays disabled until there is one.
    private var selectPlaylistCard: some View {
        DSCard {
            HStack(spacing: DSSpacing.space4) {
                DSCoverMosaic(covers: [])
                    .frame(width: Self.coverSide, height: Self.coverSide)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusCard, style: .continuous))
                VStack(alignment: .leading, spacing: DSSpacing.space2) {
                    DSText(style: .headline)
                        .localized("providerStarter.selectPlaylist.title")
                    DSText(style: .subheadline)
                        .localized("providerStarter.selectPlaylist.message")
                    NavigationLink(value: ProviderStarterCoordinator.Route.playlistSelector) {
                        Text(String(localized: "providerStarter.selectPlaylist.action"))
                    }
                    .buttonStyle(DSButtonStyle(style: .plain))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var selectedPlaylistContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(maxWidth: .infinity)
        case .loaded:
            if let playlist = viewModel.selectedPlaylist {
                playlistRow(playlist)
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                DSText(message, style: .footnote, color: DSColor.destructive)
                DSButton(style: .plain) {
                    Task { await viewModel.load() }
                }
                .localized("providerStarter.retry")
            }
        }
    }

    private func playlistRow(_ playlist: ProviderStarterViewData.Playlist) -> some View {
        HStack(spacing: DSSpacing.space4) {
            DSCoverMosaic(covers: playlist.covers)
                .frame(width: Self.coverSide, height: Self.coverSide)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusCard, style: .continuous))
                .dsShadow(.card)
            VStack(alignment: .leading, spacing: DSSpacing.space1) {
                DSText(playlist.name, style: .headline)
                    .lineLimit(2)
                DSText(viewModel.songCountText(for: playlist), style: .subheadline)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var play: some View {
        VStack(spacing: DSSpacing.space3) {
            DSIconButton(systemImage: "play.fill", style: .play, diameter: Self.playDiameter) {
                Task { await viewModel.didTapPlay() }
            }
            .localized("providerStarter.play.accessibility")
            .disabled(viewModel.selectedPlaylist == nil || viewModel.isStartingGame)
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

    private var choosePlaylist: some View {
        NavigationLink(value: ProviderStarterCoordinator.Route.playlistSelector) {
            Label(
                String(localized: "providerStarter.choosePlaylist"),
                systemImage: "text.line.first.and.arrowtriangle.forward"
            )
        }
        .buttonStyle(DSButtonStyle(style: .secondary))
    }
}

#Preview {
    NavigationStack {
        ProviderStarterCoordinator(provider: .appleMusic, signOut: {}).start()
    }
}
