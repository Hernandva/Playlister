import SwiftUI

/// Bottom sheet of the design system: a `title`, a `message` and one or two stacked actions,
/// on the aura background with `radius-sheet` corners and the drag indicator.
///
/// It sizes itself to its content. Present it from `.sheet(item:)` or `.sheet(isPresented:)`:
///
///     .sheet(item: $viewModel.error) { error in
///         DSBottomSheet(
///             title: error.title,
///             message: error.message,
///             primaryAction: .init(String(localized: "common.accept")) { viewModel.dismissError() }
///         )
///     }
///
/// Texts are passed already localised.
public struct DSBottomSheet: View {
    /// A button of the sheet.
    public struct Action {
        let title: String
        let style: DSButton.Style
        let handler: @MainActor () -> Void

        public init(_ title: String, style: DSButton.Style = .primary, handler: @escaping @MainActor () -> Void) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }

    private let title: String
    private let message: String
    private let primaryAction: Action
    private let secondaryAction: Action?
    @State private var contentHeight: CGFloat = 0

    /// - Parameters:
    ///   - primaryAction: Main button, `.primary` by default.
    ///   - secondaryAction: Optional button under it. Pass `style: .plain` for "Not now" or "Cancel".
    public init(title: String, message: String, primaryAction: Action, secondaryAction: Action? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    public var body: some View {
        VStack(spacing: DSSpacing.space4) {
            DSText(title, style: .title)
                .accessibilityAddTraits(.isHeader)
            DSText(message, style: .body, color: DSColor.textSecondary)
            VStack(spacing: DSSpacing.space2) {
                button(for: primaryAction)
                if let secondaryAction {
                    button(for: secondaryAction)
                }
            }
            .padding(.top, DSSpacing.space2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, DSSpacing.space6)
        .padding(.top, DSSpacing.space8)
        .padding(.bottom, DSSpacing.space6)
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            contentHeight = height
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DSRadius.radiusSheet)
        .presentationBackground { DSAuraBackground() }
        .tint(DSPalette.bubblegum)
        .preferredColorScheme(.dark)
    }

    private func button(for action: Action) -> some View {
        DSButton(action.title, style: action.style, action: action.handler)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DSBottomSheet(
                title: "Da permiso a Apple Music",
                message: "Playlister no tiene acceso a Apple Music. Abre los ajustes y dale permiso.",
                primaryAction: .init("Ir a Ajustes") {},
                secondaryAction: .init("Ahora no", style: .plain) {}
            )
        }
        .background { DSAuraBackground() }
}
