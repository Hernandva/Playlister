import PlaylisterUI
import SwiftUI

/// Hosts the navigation stack and starts the root feature.
/// The root feature is declared in FEATURES.md; every other scene is reached from it.
struct RootView: View {
    /// Kept in state so the coordinator, and the route it presents, survive body updates.
    @State private var homeCoordinator = HomeCoordinator()

    var body: some View {
        NavigationStack {
            homeCoordinator.start()
        }
        .tint(DSColor.accent)
    }
}
