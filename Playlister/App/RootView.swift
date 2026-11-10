import PlaylisterUI
import SwiftUI

/// Hosts the navigation stack and starts the root feature.
/// The root feature is declared in FEATURES.md; every other scene is reached from it.
struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeCoordinator().start()
        }
        .tint(DSColor.accent)
    }
}
