import SwiftUI
import TimelyKit

/// Range totals.
///
/// The provenance line is not decoration. A local rollup and a server summary
/// can legitimately differ — this device may not hold every other device's
/// spans — and a report that does not say which one it is showing is a report
/// someone will invoice from by mistake.
struct ReportsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = ReportsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $model.preset) {
                        ForEach(ReportsViewModel.Preset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Group by", selection: $model.groupBy) {
                        Text("Client").tag(ReportGroupKey.client)
                        Text("Project").tag(ReportGroupKey.project)
                        Text("Ticket").tag(ReportGroupKey.ticket)
                        Text("Day").tag(ReportGroupKey.day)
                        Text("Source").tag(ReportGroupKey.source)
                    }
                } footer: {
                    Text(model.sourceExplanation)
                }

                totalsSection
                warningsSection
                groupsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reports")
            .refreshable { await model.load(environment: environment) }
            .task(id: environment.phase) { await model.load(environment: environment) }
            .task(id: model.preset) { await model.load(environment: environment) }
            .task(id: model.groupBy) { await model.load(environment: environment) }
        }
    }

    // MARK: - Sections

    private var totalsSection: some View {
        Section("Totals") {
            let totals = model.summary?.totals

            DetailRow(
                label: "Tracked",
                value: TimelyFormat.duration(
                    totals.map { TimeInterval($0.elapsedSeconds) } ?? model.localRollup.elapsed
                ),
                symbolName: "clock"
            )
            DetailRow(
                label: "Billable",
                value: TimelyFormat.decimalHours(
                    totals.map { TimeInterval($0.billableSeconds) } ?? model.localRollup.billable
                ) + " h",
                symbolName: "dollarsign.circle"
            )
            DetailRow(
                label: "Billable, overlap-adjusted",
                value: TimelyFormat.decimalHours(
                    totals.map { TimeInterval($0.weightedBillableSeconds) }
                        ?? model.localRollup.weightedBillable
                ) + " h",
                symbolName: "arrow.triangle.branch"
            )
            DetailRow(
                label: "Intervals",
                value: "\(totals?.spanCount ?? model.localRollup.spanCount)",
                symbolName: "list.bullet"
            )
            DetailRow(
                label: "Needs review",
                value: "\(totals?.needsReviewCount ?? model.localRollup.needsReviewCount)",
                symbolName: "exclamationmark.triangle"
            )
            if let totals {
                DetailRow(
                    label: "Backed by evidence",
                    value: TimelyFormat.percent(totals.evidenceCoverage),
                    symbolName: "checkmark.seal"
                )
            }
        }
    }

    @ViewBuilder
    private var warningsSection: some View {
        let serverWarnings = model.summary?.warnings ?? []

        if !serverWarnings.isEmpty {
            Section {
                ForEach(Array(serverWarnings.enumerated()), id: \.offset) { _, warning in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warning.message)
                                .font(.footnote)
                            Text("\(warning.count) affected")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(
                                model.blockingWarnings.contains(warning)
                                    ? TimelyTheme.danger : TimelyTheme.warning
                            )
                    }
                }
            } header: {
                Text("Before you invoice")
            } footer: {
                Text(model.blockingWarnings.isEmpty
                     ? "Nothing here blocks an invoice."
                     : "Resolve these in Review first — each one means two records claim the "
                        + "same time.")
            }
        } else if !model.localWarningText.isEmpty {
            Section {
                ForEach(model.localWarningText, id: \.self) { text in
                    Label(text, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                }
            } header: {
                Text("Before you invoice")
            } footer: {
                Text("Checked on this device only.")
            }
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        if let groups = model.summary?.groups, !groups.isEmpty {
            Section("Breakdown") {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    groupRow(
                        label: group.label,
                        parent: group.parentLabel,
                        elapsed: TimeInterval(group.elapsedSeconds),
                        weighted: TimeInterval(group.weightedBillableSeconds),
                        count: group.spanCount
                    )
                }
            }
        } else if !model.localGroups.isEmpty {
            Section("Breakdown") {
                ForEach(model.localGroups) { group in
                    groupRow(
                        label: group.label,
                        parent: group.parentLabel,
                        elapsed: group.elapsed,
                        weighted: group.weightedBillable,
                        count: group.spanCount
                    )
                }
            }
        } else {
            Section {
                EmptyStateRow(message: "No time in this range.", symbolName: "chart.bar")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }

    private func groupRow(
        label: String,
        parent: String?,
        elapsed: TimeInterval,
        weighted: TimeInterval,
        count: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                if let parent {
                    Text(parent)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(count) interval(s)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: TimelyTheme.Space.compact)
            VStack(alignment: .trailing, spacing: 2) {
                Text(TimelyFormat.duration(elapsed))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                if weighted > 0 {
                    Text(TimelyFormat.decimalHours(weighted) + " h billable")
                        .font(.caption2)
                        .foregroundStyle(TimelyTheme.success)
                        .monospacedDigit()
                }
            }
        }
    }
}
