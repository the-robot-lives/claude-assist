import SwiftUI

enum TimelyTheme {
    static let accent = Color(red: 0.84, green: 0.12, blue: 0.45)
    static let accentSoft = Color(red: 0.84, green: 0.12, blue: 0.45).opacity(0.11)
    static let teal = Color(red: 0.02, green: 0.58, blue: 0.62)
    static let violet = Color(red: 0.43, green: 0.29, blue: 0.88)
    static let gold = Color(red: 0.86, green: 0.55, blue: 0.12)
    static let success = Color(red: 0.10, green: 0.64, blue: 0.32)
    static let warning = Color(red: 0.78, green: 0.48, blue: 0.10)
    static let danger = Color(red: 0.78, green: 0.14, blue: 0.14)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let elevated = Color(nsColor: .textBackgroundColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.45)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)

    static let radius: CGFloat = 8
    static let gap: CGFloat = 16
    static let pagePadding: CGFloat = 24

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [accent, violet, teal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.16), gold.opacity(0.10), teal.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct TimelyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                TimelyTheme.brandGradient
                    .opacity(configuration.isPressed ? 0.82 : 1)
            )
            .shadow(color: TimelyTheme.accent.opacity(0.18), radius: 8, y: 3)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TimelySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(TimelyTheme.surface.opacity(configuration.isPressed ? 0.72 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(TimelyTheme.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TimelyIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .background(TimelyTheme.surface.opacity(configuration.isPressed ? 0.72 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(TimelyTheme.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TimelyCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(padding)
            .background(
                ZStack {
                    TimelyTheme.elevated
                    TimelyTheme.warmGradient
                        .opacity(0.16)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: TimelyTheme.radius)
                    .stroke(TimelyTheme.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: TimelyTheme.radius))
    }
}

extension View {
    func timelyCard(padding: CGFloat = 16) -> some View {
        modifier(TimelyCardModifier(padding: padding))
    }
}

struct TimelyStatusPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(tint.opacity(0.10))
            .clipShape(Capsule())
    }
}

struct TimelyPageHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(TimelyTheme.brandGradient)
                .frame(width: 5, height: 74)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(TimelyTheme.accent)
                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(TimelyTheme.secondaryText)
            }
            Spacer(minLength: 24)
            trailing
        }
    }
}

struct TimelyMetricTile: View {
    let label: String
    let value: String
    let detail: String
    let systemImage: String
    var tint: Color = TimelyTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TimelyTheme.secondaryText)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption)
                .foregroundStyle(TimelyTheme.secondaryText)
                .lineLimit(2)
        }
        .timelyCard(padding: 14)
    }
}
