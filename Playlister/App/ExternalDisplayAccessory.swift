import SwiftUI
import UIKit

extension View {
    /// Asks iOS to give the external display (a TV through AirPlay or a cable) its own scene while this view is on
    /// screen, instead of mirroring the iPhone. The scene shows `ExternalDisplayRootView` through
    /// `ExternalDisplaySceneDelegate`.
    ///
    /// From iOS 27 the system only connects that scene for a view controller that registers a `UISceneAccessory`;
    /// before iOS 27 it connects it on its own (see `AppDelegate`) and this does nothing.
    func externalDisplayAccessory() -> some View {
        background {
            ExternalDisplayAccessoryRegistrar()
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}

/// Puts `ExternalDisplayAccessoryViewController` in the view hierarchy, so the registration lives as long as the view.
private struct ExternalDisplayAccessoryRegistrar: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ExternalDisplayAccessoryViewController {
        ExternalDisplayAccessoryViewController()
    }

    func updateUIViewController(_ controller: ExternalDisplayAccessoryViewController, context: Context) {}
}

/// Registers the non-interactive external display accessory when it appears, and gives it up when it goes away.
/// The system connects the scene only while this controller is on screen and a display is available.
private final class ExternalDisplayAccessoryViewController: UIViewController {
    /// Name of the external display's scene configuration in Info.plist (`UIApplicationSceneManifest`).
    private static let configurationName = "External Display"

    /// The `UISceneAccessoryRegistration` on iOS 27, kept untyped so the class builds for iOS 18.
    private var registration: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard #available(iOS 27, *), registration == nil else { return }
        let configuration = UISceneConfiguration(
            name: Self.configurationName,
            sessionRole: .windowExternalDisplayNonInteractive
        )
        configuration.delegateClass = ExternalDisplaySceneDelegate.self
        registration = registerSceneAccessory(.externalNonInteractive(sceneConfiguration: configuration))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard #available(iOS 27, *), let registration = registration as? UISceneAccessoryRegistration else { return }
        unregisterSceneAccessory(registration)
        self.registration = nil
    }
}
