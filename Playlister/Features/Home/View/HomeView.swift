import PlaylisterUI
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("home.title")

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded:
                // Compose the screen with PlaylisterUI components fed by HomeViewData.
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
        HomeCoordinator().start()
    }
}
