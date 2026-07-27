import SwiftUI

/// The macOS style guide, translated to iOS.
///
/// "Minimal Tech 80%, Editorial 20% … calm, precise, serious." The desktop
/// guide's density survives the translation; its sidebars do not. What carries
/// over unchanged is the token set, the rule that a status is never colour
/// alone, and the refusal of decorative dashboard cards that make a timeline
/// harder to scan.
enum TimelyTheme {

    // MARK: - Palette

    /// Primary actions, active navigation, AI project labels.
    static let accent = Color(red: 0xD6 / 255, green: 0x1F / 255, blue: 0x73 / 255)

    /// Enabled states, billable and valid indicators.
    static let success = Color(red: 0x1A / 255, green: 0xA3 / 255, blue: 0x52 / 255)

    /// Paused state, likely project switch.
    static let warning = Color(red: 0xC7 / 255, green: 0x7A / 255, blue: 0x1A / 255)

    /// Errors and destructive actions.
    static let danger = Color(red: 0xC7 / 255, green: 0x24 / 255, blue: 0x24 / 255)

    // MARK: - Geometry

    /// Cards, list rows, thumbnails.
    static let radius: CGFloat = 8

    /// Primary and secondary buttons.
    static let buttonRadius: CGFloat = 6

    /// 8pt base; 12 for compact groups, 16 for cards, 20 for page padding.
    /// (The desktop guide says 24; a phone gutter that wide eats the density
    /// the timeline depends on.)
    enum Space {
        static let tight: CGFloat = 4
        static let compact: CGFloat = 8
        static let group: CGFloat = 12
        static let card: CGFloat = 16
        static let page: CGFloat = 20
    }

    // MARK: - Semantic colour

    static func tint(for state: ConfidenceState) -> Color {
        switch state {
        case .verified: success
        case .inferred: warning
        case .manual: .secondary
        case .private: .indigo
        case .disputed: danger
        case .approved: accent
        }
    }
}

extension View {
    /// The standard surface: one card, content sitting directly on it. The
    /// style guide forbids nesting cards inside cards.
    func timelyCard(padding: CGFloat = TimelyTheme.Space.card) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: TimelyTheme.radius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}
