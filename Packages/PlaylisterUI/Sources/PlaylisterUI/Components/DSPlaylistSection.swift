import SwiftUI

/// State of a section that loads on its own.
public enum DSSectionState: Equatable, Sendable {
    /// Not asked for yet: the section is hidden.
    case idle
    /// Shows a loading indicator under the header.
    case loading
    /// Shows its carousel, or hides itself when it has no items.
    case loaded
    /// Shows an error with a «Try again» button.
    case failed
}

/// What one card of a `DSPlaylistSection` shows. Texts are passed localised.
public struct DSPlaylistSectionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    /// Up to 4 covers: 4 make a 2×2 mosaic, fewer show the first one.
    public let covers: [URL]

    public init(id: String, name: String, subtitle: String, covers: [URL]) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.covers = covers
    }
}

/// Texts of a `DSPlaylistSection`, passed localised.
public struct DSPlaylistSectionTexts: Sendable {
    let title: String
    let count: String?
    let errorMessage: String
    let retry: String
    let cardHint: String?

    /// - Parameters:
    ///   - count: Shown at the end of the header once loaded, e.g. «12».
    ///   - errorMessage: Shown when the section fails to load.
    ///   - retry: Title of the button under the error.
    ///   - cardHint: Accessibility hint of every card, e.g. what tapping it does.
    public init(title: String, count: String? = nil, errorMessage: String, retry: String, cardHint: String? = nil) {
        self.title = title
        self.count = count
        self.errorMessage = errorMessage
        self.retry = retry
        self.cardHint = cardHint
    }
}

/// What a `DSPlaylistSection` does when the user acts on it.
public struct DSPlaylistSectionActions {
    let select: @MainActor (DSPlaylistSectionItem) -> Void
    let retry: @MainActor @Sendable () -> Void
    let cardAppear: @MainActor @Sendable (DSPlaylistSectionItem) async -> Void

    /// - Parameters:
    ///   - select: A card was tapped.
    ///   - retry: «Try again» under the error.
    ///   - cardAppear: Runs while a card is on screen, e.g. to load its covers. Cancelled when it disappears.
    public init(
        select: @escaping @MainActor (DSPlaylistSectionItem) -> Void,
        retry: @escaping @MainActor @Sendable () -> Void,
        cardAppear: @escaping @MainActor @Sendable (DSPlaylistSectionItem) async -> Void = { _ in }
    ) {
        self.select = select
        self.retry = retry
        self.cardAppear = cardAppear
    }
}

/// Section of playlists that loads on its own: a `sectionTitle` header, then a loading indicator, an error with a
/// `.plain` «Try again» button, or a horizontal carousel of `DSPlaylistCard`s that runs to the screen edges.
/// It hides itself while `.idle` and once `.loaded` with no items.
///
/// - `cardSize`: 200 pt for featured playlists, 150 pt for the rest (see `DSPlaylistCard`).
/// - `tail` goes after the last card, e.g. a loader that asks for the next page.
/// - Place it inside a `DSScreen`, whose `space-4` margins the carousel bleeds into.
public struct DSPlaylistSection<Tail: View>: View {
    private let texts: DSPlaylistSectionTexts
    private let state: DSSectionState
    private let items: [DSPlaylistSectionItem]
    private let cardSize: CGFloat
    private let actions: DSPlaylistSectionActions
    private let tail: Tail

    public init(
        _ texts: DSPlaylistSectionTexts,
        state: DSSectionState,
        items: [DSPlaylistSectionItem],
        cardSize: CGFloat = 150,
        actions: DSPlaylistSectionActions,
        @ViewBuilder tail: () -> Tail
    ) {
        self.texts = texts
        self.state = state
        self.items = items
        self.cardSize = cardSize
        self.actions = actions
        self.tail = tail()
    }

    public var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: DSSpacing.space3) {
                header
                content
            }
        }
    }

    private var isVisible: Bool {
        switch state {
        case .idle: false
        case .loading, .failed: true
        case .loaded: !items.isEmpty
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            DSText(texts.title, style: .sectionTitle)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let count = texts.count, state == .loaded {
                DSText(count, style: .subheadline, color: DSColor.textSecondary)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .tint(DSColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: cardSize)
        case .failed:
            VStack(alignment: .leading, spacing: DSSpacing.space2) {
                DSText(texts.errorMessage, style: .footnote, color: DSColor.destructive)
                DSButton(texts.retry, style: .plain, action: actions.retry)
            }
        case .loaded:
            carousel
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: DSSpacing.space3) {
                ForEach(items) { item in
                    card(item)
                }
                tail
            }
            .padding(.horizontal, DSSpacing.space4)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -DSSpacing.space4)
    }

    private func card(_ item: DSPlaylistSectionItem) -> some View {
        Button {
            actions.select(item)
        } label: {
            DSPlaylistCard(item.name, subtitle: item.subtitle, covers: item.covers, size: cardSize)
        }
        .buttonStyle(.plain)
        .accessibilityHint(texts.cardHint ?? "")
        .task { await actions.cardAppear(item) }
    }
}

public extension DSPlaylistSection where Tail == EmptyView {
    /// A section with nothing after its last card.
    init(
        _ texts: DSPlaylistSectionTexts,
        state: DSSectionState,
        items: [DSPlaylistSectionItem],
        cardSize: CGFloat = 150,
        actions: DSPlaylistSectionActions
    ) {
        self.init(texts, state: state, items: items, cardSize: cardSize, actions: actions) { EmptyView() }
    }
}

#Preview {
    let items = ["Hitster España", "Hitster Rock", "Hitster 80s"].map {
        DSPlaylistSectionItem(id: $0, name: $0, subtitle: "Apple Music", covers: [])
    }
    let actions = DSPlaylistSectionActions(select: { _ in }, retry: {})
    return DSScreen {
        DSPlaylistSection(
            DSPlaylistSectionTexts(title: "Recomendadas", count: "3", errorMessage: "Error", retry: "Reintentar"),
            state: .loaded,
            items: items,
            cardSize: 200,
            actions: actions
        )
        DSPlaylistSection(
            DSPlaylistSectionTexts(title: "Tus listas", errorMessage: "Error", retry: "Reintentar"),
            state: .loading,
            items: [],
            actions: actions
        )
        DSPlaylistSection(
            DSPlaylistSectionTexts(
                title: "Resultados",
                errorMessage: "No se pudieron cargar estas listas.",
                retry: "Reintentar"
            ),
            state: .failed,
            items: [],
            actions: actions
        )
    }
}
