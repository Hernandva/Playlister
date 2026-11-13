import UIKit

/// Gives the external display (a TV through AirPlay or a cable) its own scene, so it shows the game laid out for a
/// TV instead of mirroring the iPhone. Every other scene keeps SwiftUI's default configuration.
///
/// Before iOS 27 the system connects that scene whenever a display is there. From iOS 27 it only connects it for a
/// registered scene accessory: the game registers one with `externalDisplayAccessory()`, with the same
/// configuration and delegate.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Name of the external display's scene configuration in Info.plist (`UIApplicationSceneManifest`).
    private static let externalDisplayConfiguration = "External Display"

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        guard connectingSceneSession.role == .windowExternalDisplayNonInteractive else {
            return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        }
        // Declared in Info.plist: iOS only hands the display to the app, instead of mirroring it, when it is there.
        let configuration = UISceneConfiguration(
            name: Self.externalDisplayConfiguration,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = ExternalDisplaySceneDelegate.self
        return configuration
    }
}
