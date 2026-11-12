import PlaylisterUI
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: SettingsDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("settings.title")

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
        SettingsCoordinator().start()
    }
}
