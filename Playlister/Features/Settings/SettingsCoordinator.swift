import SwiftUI

/// Entry point of the Settings feature.
/// Builds the view through `SettingsDependencies` and resolves the routes to the features opened from it.
@MainActor
final class SettingsCoordinator: Coordinator {
    /// One case per feature that can be opened from Settings.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: SettingsDependencies

    init(dependencies: SettingsDependencies = SettingsDependencies()) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        SettingsView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        // @codegen:destinations
        }
    }
}
