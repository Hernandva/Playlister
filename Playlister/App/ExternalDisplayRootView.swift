import PlaylisterUI
import SwiftUI

/// Root of the external display (a TV through AirPlay or a cable): the game while one is played on the iPhone
/// (`GameExternalDisplayView`), and a welcome screen that asks to start one otherwise.
struct ExternalDisplayRootView: View {
    let session: GameExternalDisplaySession

    var body: some View {
        Group {
            if let game = session.game {
                GameExternalDisplayView(viewModel: game)
            } else {
                waiting
            }
        }
        .animation(.easeOut(duration: 0.4), value: session.game == nil)
    }

    private var waiting: some View {
        DSExternalDisplayCanvas {
            VStack(spacing: DSSpacing.space4) {
                DSText(style: .hero).localized("externalDisplay.waiting.title")
                DSText(style: .headline, color: DSColor.textSecondary).localized("externalDisplay.waiting.message")
            }
            .multilineTextAlignment(.center)
        }
    }
}
