import SwiftUI
import TimelyKit

/// Icon, label, semantic colour — never colour alone.
///
/// The accessibility rule from the style guide is enforced by the type: there
/// is no initializer that takes a colour without a label and a symbol.
struct StatusPill: View {
    let label: String
    let symbolName: String
    var tint: Color = .secondary
    var isProminent = false

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Image(systemName: symbolName)
        }
        .font(.caption.weight(.medium))
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, TimelyTheme.Space.compact)
        .padding(.vertical, TimelyTheme.Space.tight)
        .background(
            Capsule().fill(tint.opacity(isProminent ? 0.20 : 0.12))
        )
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

extension StatusPill {
    init(_ state: ConfidenceState) {
        self.init(
            label: state.label,
            symbolName: state.symbolName,
            tint: TimelyTheme.tint(for: state),
            isProminent: state == .disputed
        )
    }
}

/// Icon, label, large value, short detail.
struct MetricTile: View {
    let label: String
    let value: String
    var detail: String?
    var symbolName: String?
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
            HStack(spacing: TimelyTheme.Space.tight) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.caption)
                        .foregroundStyle(tint)
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .timelyCard(padding: TimelyTheme.Space.group)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(detail.map { ". \($0)" } ?? "")")
    }
}

/// A compact neutral row with a concrete next step. Never a full-page
/// illustration — the guide calls those out by name.
struct EmptyStateRow: View {
    let message: String
    var symbolName: String = "tray"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: TimelyTheme.Space.group) {
            Image(systemName: symbolName)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.medium))
                    .buttonStyle(.borderless)
            }
        }
        .timelyCard(padding: TimelyTheme.Space.group)
    }
}

struct SectionHeading: View {
    let title: String
    var detail: String?
    var trailing: AnyView?

    init(_ title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
        self.trailing = nil
    }

    init<Trailing: View>(_ title: String, detail: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.detail = detail
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: TimelyTheme.Space.compact)
            trailing
        }
        .padding(.top, TimelyTheme.Space.compact)
    }
}

/// One interval, dense enough to scan a day of them.
struct SpanRow: View {
    let span: TimeSpan
    var confidence: ConfidenceState
    var weightedSeconds: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: TimelyTheme.Space.compact) {
            HStack(alignment: .firstTextBaseline, spacing: TimelyTheme.Space.compact) {
                Text(span.title.isEmpty ? "Untitled interval" : span.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Spacer(minLength: TimelyTheme.Space.tight)
                Text(TimelyFormat.duration(span.duration()))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }

            HStack(spacing: TimelyTheme.Space.compact) {
                Text(TimelyFormat.range(start: span.start, end: span.end))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(TimelyFormat.taxonomyLabel(
                    client: span.clientName, project: span.projectName, ticket: span.ticketName
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            HStack(spacing: TimelyTheme.Space.compact) {
                StatusPill(confidence)

                if span.isBillable {
                    StatusPill(
                        label: "Billable", symbolName: "dollarsign.circle",
                        tint: TimelyTheme.success
                    )
                }
                if span.isOpen {
                    StatusPill(label: "Open", symbolName: "record.circle", tint: TimelyTheme.warning)
                }
                if span.sync.isLocalOnly {
                    // Honest label: the row exists here and nowhere else yet.
                    StatusPill(label: "Not synced", symbolName: "icloud.slash", tint: .secondary)
                }
                if let weightedSeconds, weightedSeconds + 1 < span.duration(), span.isBillable {
                    StatusPill(
                        label: "Shared \(TimelyFormat.duration(weightedSeconds))",
                        symbolName: "arrow.triangle.branch",
                        tint: TimelyTheme.warning
                    )
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, TimelyTheme.Space.tight)
        .contentShape(Rectangle())
    }
}

/// A banner that reports state without blocking anything behind it.
struct NoticeBanner: View {
    let title: String
    let message: String
    var symbolName: String
    var tint: Color
    var actionTitle: String?
    var action: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: TimelyTheme.Space.group) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .font(.body.weight(.medium))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderless)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss")
            }
        }
        .timelyCard(padding: TimelyTheme.Space.group)
        .overlay(
            RoundedRectangle(cornerRadius: TimelyTheme.radius, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }
}

/// A field label above a value, for read-only detail rows.
struct DetailRow: View {
    let label: String
    let value: String
    var symbolName: String?

    var body: some View {
        HStack(spacing: TimelyTheme.Space.compact) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
            }
            Text(label)
                .font(.subheadline)
            Spacer(minLength: TimelyTheme.Space.compact)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
