import SwiftUI

struct RootView: View {
    @Binding var store: TimelyStore

    var body: some View {
        TabView {
            DashboardScreen(store: $store)
                .tabItem {
                    Label("Today", systemImage: "clock")
                }

            TimelineScreen(intervals: store.intervals)
                .tabItem {
                    Label("Timeline", systemImage: "rectangle.stack")
                }

            ReportsScreen(reports: store.reports)
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }

            PrivacyScreen(policy: store.policy)
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
    }
}

struct DashboardScreen: View {
    @Binding var store: TimelyStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timely")
                                .font(.largeTitle.bold())
                            Text(store.paused ? "Capture paused" : "Review companion")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(store.paused ? "Resume" : "Pause") {
                            store.paused.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(label: "Reviewed", value: String(format: "%.1f", store.summary.reviewedHours), detail: "hours today")
                        MetricCard(label: "Billable", value: String(format: "%.2f", store.summary.billableHours), detail: "ready for export")
                        MetricCard(label: "Confidence", value: "\(store.summary.confidence)%", detail: "verified ledger")
                        MetricCard(label: "Prompts", value: "\(store.summary.unresolvedPrompts)", detail: "needs review")
                    }

                    SectionHeading(title: "Idle prompts", detail: "Resolve useful decisions from return events")

                    ForEach(store.prompts) { prompt in
                        PromptRow(prompt: prompt)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 30, weight: .semibold))
                .monospacedDigit()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

struct TimelineScreen: View {
    let intervals: [TimelyInterval]

    var body: some View {
        NavigationStack {
            List(intervals) { interval in
                IntervalRow(interval: interval)
            }
            .navigationTitle("Timeline")
        }
    }
}

struct IntervalRow: View {
    let interval: TimelyInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(interval.task)
                    .font(.headline)
                Spacer()
                Text("\(interval.confidence)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.blue)
            }
            Text("\(interval.start)-\(interval.end) / \(interval.project)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(interval.state.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
}

struct ReportsScreen: View {
    let reports: [ClientReport]

    var body: some View {
        NavigationStack {
            List(reports) { report in
                VStack(alignment: .leading, spacing: 8) {
                    Text(report.client)
                        .font(.headline)
                    Text(String(format: "%.2f hours / %d%% confidence", report.hours, report.confidence))
                        .foregroundStyle(.secondary)
                    Text(report.evidence)
                        .font(.caption)
                }
            }
            .navigationTitle("Reports")
        }
    }
}

struct PrivacyScreen: View {
    let policy: TimelyPolicy

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Screenshot interval", value: "\(policy.screenshotIntervalMinutes) minutes")
                LabeledContent("Local-only screenshots", value: policy.localOnlyScreenshots ? "Enabled" : "Disabled")
                LabeledContent("Retention", value: "\(policy.retentionDays) days")
                LabeledContent("Excluded apps", value: policy.excludedApps.joined(separator: ", "))
            }
            .navigationTitle("Privacy")
        }
    }
}

struct PromptRow: View {
    let prompt: IdlePrompt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt.window)
                .font(.headline)
            Text(prompt.suggestion)
            Text(prompt.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SectionHeading: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}

