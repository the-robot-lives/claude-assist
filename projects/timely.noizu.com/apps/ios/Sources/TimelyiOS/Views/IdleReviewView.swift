import SwiftUI
import TimelyKit

/// Account for time nothing explains.
///
/// Each gap shows what came before and after it, because that is the context
/// people actually use to remember what they were doing. The two answers are
/// symmetric in weight — accounting for a gap is not "correct" and dismissing
/// it "lazy" — but they are not symmetric in reach, and the screen says which
/// one leaves this device.
struct IdleReviewView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = IdleReviewViewModel()
    @State private var accounting: IdleGap?

    var body: some View {
        List {
            if model.days.isEmpty {
                Section {
                    EmptyStateRow(
                        message: model.isLoading
                            ? "Looking for unaccounted time…"
                            : "No unaccounted time in the last \(model.lookbackDays) days.",
                        symbolName: "checkmark.circle"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    DetailRow(
                        label: "Unaccounted",
                        value: TimelyFormat.duration(model.totalUnaccounted),
                        symbolName: "moon.zzz"
                    )
                    DetailRow(
                        label: "Counted as a gap after",
                        value: TimelyFormat.duration(model.idleThreshold),
                        symbolName: "timer"
                    )
                }
            }

            ForEach(model.days) { day in
                Section(TimelyFormat.dayTitle(day.date)) {
                    ForEach(day.gaps) { gap in
                        gapRow(gap)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Idle review")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.load(environment: environment) }
        .task(id: environment.phase) { await model.load(environment: environment) }
        .sheet(item: $accounting) { gap in
            ManualEntryView(gap: gap) {
                Task { await model.load(environment: environment) }
            }
        }
    }

    @ViewBuilder
    private func gapRow(_ gap: IdleGap) -> some View {
        let neighbours = model.context(for: gap)

        VStack(alignment: .leading, spacing: TimelyTheme.Space.compact) {
            HStack(alignment: .firstTextBaseline) {
                Text(TimelyFormat.range(start: gap.start, end: gap.end))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                Spacer()
                Text(TimelyFormat.duration(gap.duration))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(TimelyTheme.warning)
            }

            if let before = neighbours.before {
                Label("After: \(before.title.isEmpty ? "Untitled" : before.title)",
                      systemImage: "arrow.up.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let after = neighbours.after {
                Label("Before: \(after.title.isEmpty ? "Untitled" : after.title)",
                      systemImage: "arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: TimelyTheme.Space.compact) {
                Button("Account for it") { accounting = gap }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button("Not work") {
                    Task { await model.dismiss(gap, environment: environment) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, TimelyTheme.Space.tight)

            Text("“Not work” is remembered on this device only — unaccounted time has no "
                 + "record on the server to mark.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, TimelyTheme.Space.tight)
    }
}
