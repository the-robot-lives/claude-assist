import SwiftUI

enum Brand {
    static let page = Color(red: 0.06, green: 0.075, blue: 0.09)
    static let panel = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let panelRaised = Color(red: 0.15, green: 0.17, blue: 0.19)
    static let line = Color.white.opacity(0.14)
    static let primary = Color(red: 0.33, green: 0.74, blue: 0.96)
    static let secondary = Color(red: 0.92, green: 0.73, blue: 0.24)
    static let good = Color(red: 0.36, green: 0.78, blue: 0.51)
    static let hot = Color(red: 0.94, green: 0.35, blue: 0.27)
}

struct MetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Brand.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Brand.panelRaised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Brand.line)
        )
    }
}
