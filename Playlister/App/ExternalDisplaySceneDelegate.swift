import SwiftUI
import UIKit

/// Scene of the external display: a window that hosts `ExternalDisplayRootView` and tells the game session when the
/// display connects and disconnects. The display is not interactive: the game is played on the iPhone.
final class ExternalDisplaySceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    private let session = GameExternalDisplaySession.shared

    func scene(
        _ scene: UIScene,
        willConnectTo connectingSession: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ExternalDisplayRootView(session: session))
        window.isHidden = false
        self.window = window
        session.displayDidConnect()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        window = nil
        session.displayDidDisconnect()
    }
}
