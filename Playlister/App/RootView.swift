import PlaylisterUI
import SwiftUI

/// Hosts the navigation stack and starts the root feature.
/// The root feature is declared in FEATURES.md; every other scene is reached from it.
struct RootView: View {
    /// Kept in state so the coordinator, and the navigation path it owns, survive body updates.
    @State private var homeCoordinator = HomeCoordinator()

    var body: some View {
        NavigationStack(path: $homeCoordinator.path) {
            homeCoordinator.start()
        }
        .tint(DSColor.accent)
    }
}
