import PlaylisterUI
import SwiftUI

struct PlaylistSelectorView: View {
    @State private var viewModel: PlaylistSelectorViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: PlaylistSelectorDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("playlistSelector.title")

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded:
                // Compose the screen with PlaylisterUI components fed by `viewModel.viewData`.
                EmptyView()
            case .failed(let message):
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
        }
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        PlaylistSelectorCoordinator().start()
    }
}
