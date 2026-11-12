import PlaylisterUI
import SwiftUI

/// Settings: what each round plays, the game mode, the Bingo categories and the account.
/// Every change is saved as soon as it is made.
struct SettingsView: View {
    /// Keeps the column readable on iPad.
    private static let maxContentWidth: CGFloat = 480

    @State private var viewModel: SettingsViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: SettingsDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            VStack(alignment: .leading, spacing: DSSpacing.space6) {
                DSText(style: .largeTitle)
                    .localized("settings.title")
                    .accessibilityAddTraits(.isHeader)
                content
            }
            .frame(maxWidth: Self.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(maxWidth: .infinity)
        case .loaded:
            playbackSection
            gameModeSection
            if viewModel.gameMode == .bingo {
                bingoSection
                    .transition(.opacity)
            }
            accountSection
            if let message = viewModel.saveErrorMessage {
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                DSText(message, style: .footnote, color: DSColor.destructive)
                DSButton(style: .plain) {
                    Task { await viewModel.load() }
                }
                .localized("settings.retry")
            }
        }
    }

    // MARK: Playback

    private var playbackSection: some View {
        section(header: "settings.playback.header", footer: viewModel.playbackFooter) {
            DSListGroup {
                segmented(selection: $viewModel.playback, segments: [
                    .init(.fullSong, title: String(localized: "settings.playback.fullSong")),
                    .init(.clip, title: String(localized: "settings.playback.clip"))
                ])
                if viewModel.playback == .clip {
                    DSSlider(
                        value: $viewModel.clipSeconds,
                        in: Self.clipSecondsBounds,
                        step: Double(SettingsViewData.Game.clipSecondsStep),
                        labels: clipSecondsLabels
                    )
                    VStack(alignment: .leading, spacing: DSSpacing.space3) {
                        DSText(style: .body).localized("settings.playback.start")
                        DSSegmentedControl(selection: $viewModel.clipStart, segments: [
                            .init(.beginning, title: String(localized: "settings.playback.start.beginning")),
                            .init(.random, title: String(localized: "settings.playback.start.random"))
                        ])
                    }
                    .padding(.horizontal, DSSpacing.space4)
                    .padding(.vertical, DSSpacing.space3)
                }
            }
            .animation(.snappy, value: viewModel.playback)
        }
    }

    private static var clipSecondsBounds: ClosedRange<Double> {
        let range = SettingsViewData.Game.clipSecondsRange
        return Double(range.lowerBound)...Double(range.upperBound)
    }

    private var clipSecondsLabels: DSSlider.Labels {
        let range = SettingsViewData.Game.clipSecondsRange
        return DSSlider.Labels(
            title: String(localized: "settings.playback.duration"),
            value: viewModel.clipSecondsText,
            minimum: SettingsViewModel.secondsText(range.lowerBound),
            maximum: SettingsViewModel.secondsText(range.upperBound)
        )
    }

    // MARK: Game mode

    private var gameModeSection: some View {
        section(header: "settings.mode.header") {
            DSListGroup {
                gameModeRow(.classic, title: "settings.mode.classic", subtitle: "settings.mode.classic.subtitle")
                gameModeRow(.bingo, title: "settings.mode.bingo", subtitle: "settings.mode.bingo.subtitle")
            }
        }
    }

    private func gameModeRow(_ mode: SettingsViewData.GameMode, title: String, subtitle: String) -> some View {
        Button {
            withAnimation(.snappy) { viewModel.gameMode = mode }
        } label: {
            DSListRow(
                String(localized: String.LocalizationValue(title)),
                subtitle: String(localized: String.LocalizationValue(subtitle)),
                accessory: viewModel.gameMode == mode ? .checkmark : .none
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Bingo

    private var bingoSection: some View {
        section(header: "settings.bingo.header", footer: viewModel.bingoFooter) {
            DSListGroup {
                segmented(selection: $viewModel.bingoLevel, segments: [
                    .init(.beginner, title: String(localized: "settings.bingo.level.beginner")),
                    .init(.expert, title: String(localized: "settings.bingo.level.expert"))
                ])
                ForEach(DSBingoCategory.allCases) { category in
                    DSBingoCategoryRow(category: category, level: viewModel.bingoLevel, isOn: Binding(
                        get: { viewModel.isCategoryOn(category) },
                        set: { viewModel.setCategory(category, isOn: $0) }
                    ))
                    .disabled(!viewModel.canTurnOff(category))
                }
            }
        }
    }

    // MARK: Account

    private var accountSection: some View {
        section(header: "settings.account.header") {
            DSListGroup {
                DSListRow(
                    viewModel.providerName,
                    accessory: .value(String(localized: "settings.account.connected"))
                )
                DSListButtonRow(style: .destructive) {
                    viewModel.didTapSignOut()
                }
                .localized("settings.account.signOut")
            }
        }
    }

    // MARK: Building blocks

    /// Header, grouped rows and an optional footer.
    private func section(
        header: String,
        footer: String? = nil,
        @ViewBuilder rows: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.space2) {
            DSSectionHeader().localized(header)
            rows()
            if let footer {
                DSText(footer, style: .footnote, color: DSColor.textSecondary)
                    .padding(.horizontal, DSSpacing.space4)
            }
        }
    }

    private func segmented<Value: Hashable>(
        selection: Binding<Value>,
        segments: [DSSegmentedControl<Value>.Segment]
    ) -> some View {
        DSSegmentedControl(selection: selection, segments: segments)
            .padding(.horizontal, DSSpacing.space4)
            .padding(.vertical, DSSpacing.space3)
    }
}

#Preview {
    NavigationStack {
        SettingsCoordinator(provider: .spotify, signOut: {}).start()
    }
}
