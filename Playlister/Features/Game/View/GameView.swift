import PlaylisterUI
import SwiftUI

struct GameView: View {
    @State private var viewModel: GameViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: GameDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("game.title")
            DSText(viewModel.viewData.playlist.name, style: .headline)

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
        GameCoordinator(
            provider: .appleMusic,
            playlist: GameViewData.Playlist(id: "preview", name: "Road Trip", songCount: 42, covers: [])
        ).start()
    }
}
