import SwiftUI

/// Song information shown when the answer is revealed: title, artist, year and extra fields.
///
/// - Classic mode: `surface-2` with the year in the animated glow.
/// - Bingo: with a `category`, the card takes its color and every text goes in `bg-night`.
///   Put the category answer first in `details` and highlight it («Década: Años 70»).
/// - `trailingDetail` goes at the trailing edge of the details row, right-aligned under the year
///   (e.g. «Duración: 5:55»).
/// - Insert it with `.transition(DSSongRevealCard.revealTransition)`: it rises 24 pt while fading in.
///
/// Strings are passed already localised.
public struct DSSongRevealCard: View {
    public struct Detail: Sendable {
        public let label: String
        public let value: String
        public let isHighlighted: Bool

        public init(_ label: String, value: String, isHighlighted: Bool = false) {
            self.label = label
            self.value = value
            self.isHighlighted = isHighlighted
        }
    }

    /// Reveal animation of the card: it rises 24 pt with a fade.
    public static var revealTransition: AnyTransition {
        .offset(y: 24).combined(with: .opacity)
    }

    private let title: String
    private let artist: String
    private let year: String
    private let details: [Detail]
    private let trailingDetail: Detail?
    private let category: DSBingoCategory?

    public init(
        title: String,
        artist: String,
        year: String,
        details: [Detail] = [],
        trailingDetail: Detail? = nil,
        category: DSBingoCategory? = nil
    ) {
        self.title = title
        self.artist = artist
        self.year = year
        self.details = details
        self.trailingDetail = trailingDetail
        self.category = category
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space3) {
            header
            if !details.isEmpty || trailingDetail != nil {
                detailsRow
            }
        }
        .padding(.horizontal, DSSpacing.space5)
        .padding(.vertical, DSSpacing.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            category?.color ?? DSPalette.surface2,
            in: RoundedRectangle(cornerRadius: DSRadius.radiusPanel, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: DSSpacing.space3) {
            VStack(alignment: .leading, spacing: DSSpacing.space1) {
                Text(title)
                    .font(DSFont.title)
                    .foregroundStyle(ink)
                Text(artist)
                    .font(DSFont.body)
                    .foregroundStyle(secondaryInk(0.75))
            }
            Spacer(minLength: 0)
            if category == nil {
                DSText(year, style: .hero)
            } else {
                DSText(year, style: .hero, color: ink)
            }
        }
    }

    private var detailsRow: some View {
        HStack(alignment: .top, spacing: DSSpacing.space6) {
            ForEach(details.indices, id: \.self) { index in
                detailView(details[index], alignment: .leading)
            }
            if let trailingDetail {
                Spacer(minLength: 0)
                detailView(trailingDetail, alignment: .trailing)
            }
        }
        .padding(.top, DSSpacing.space3)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(category == nil ? DSColor.separator : DSColor.background.opacity(0.18))
                .frame(height: 1)
        }
    }

    private func detailView(_ detail: Detail, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(detail.label)
                .font(DSFont.caption)
                .tracking(DSTextStyle.caption.tracking)
                .textCase(.uppercase)
                .foregroundStyle(secondaryInk(0.7))
            Text(detail.value)
                .font(DSTypeScale.subheadline)
                .fontWeight(detail.isHighlighted ? .bold : .regular)
                .foregroundStyle(ink)
        }
        .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
    }

    /// Main text color: `text-primary`, or `bg-night` on a category color.
    private var ink: Color {
        category?.ink ?? DSColor.textPrimary
    }

    /// Secondary text: `text-secondary`, or `bg-night` at `opacity` on a category color.
    private func secondaryInk(_ opacity: Double) -> Color {
        category.map { $0.ink.opacity(opacity) } ?? DSColor.textSecondary
    }
}

#Preview {
    VStack(spacing: DSSpacing.space4) {
        DSSongRevealCard(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            year: "1975",
            details: [.init("Álbum", value: "A Night at the Opera")],
            trailingDetail: .init("Duración", value: "5:55")
        )
        DSSongRevealCard(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            year: "1975",
            details: [
                .init("Década", value: "Años 70", isHighlighted: true),
                .init("Álbum", value: "A Night at the Opera")
            ],
            category: .green
        )
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
