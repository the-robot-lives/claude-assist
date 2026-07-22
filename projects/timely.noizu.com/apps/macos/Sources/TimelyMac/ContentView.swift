import SwiftUI

struct ContentView: View {
    @Binding var captureState: CaptureState
    @State private var selectedSection: Section = .dashboard

    enum Section: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case timeline = "Timeline"
        case evidence = "Evidence"
        case privacy = "Privacy"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selectedSection) { section in
                Text(section.rawValue)
                    .tag(section)
            }
            .navigationTitle("Timely")
        } detail: {
            VStack(alignment: .leading, spacing: 18) {
                HeaderView(captureState: $captureState)

                switch selectedSection {
                case .dashboard:
                    DashboardView(captureState: captureState)
                case .timeline:
                    TimelineView(intervals: captureState.intervals)
                case .evidence:
                    EvidenceView()
                case .privacy:
                    PrivacyView(policy: captureState.policy)
                }
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(captureState.isPaused ? "Resume" : "Pause", systemImage: captureState.isPaused ? "play.fill" : "pause.fill") {
                    captureState.isPaused.toggle()
                }
            }
            ToolbarItem {
                Button("Open Web Dashboard", systemImage: "globe") {}
            }
        }
    }
}

struct HeaderView: View {
    @Binding var captureState: CaptureState

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Desktop capture agent")
                    .font(.title.bold())
                Text(captureState.isPaused ? "Capture paused" : captureState.activeTask)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label(captureState.syncStatus, systemImage: "checkmark.seal")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.green)
        }
    }
}

struct DashboardView: View {
    let captureState: CaptureState

    var body: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                MetricTile(label: "Status", value: captureState.isPaused ? "Paused" : "Capturing", detail: "Menu bar visible")
                MetricTile(label: "Prompts", value: "\(captureState.unresolvedPrompts)", detail: "Idle/resume decisions")
                MetricTile(label: "Interval", value: "\(captureState.policy.screenshotIntervalMinutes)m", detail: "Screenshot cadence")
            }
        }

        TimelineView(intervals: captureState.intervals)
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TimelineView: View {
    let intervals: [CaptureInterval]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily timeline")
                .font(.headline)
            ForEach(intervals) { interval in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interval.task)
                            .font(.body.weight(.medium))
                        Text("\(interval.start)-\(interval.end) / \(interval.project)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(interval.state.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                    Text("\(interval.confidence)%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(12)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct EvidenceView: View {
    var body: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                EvidenceTile(title: "Timeline canvas", status: "Shareable")
                EvidenceTile(title: "Deploy logs", status: "Shareable")
                EvidenceTile(title: "Invoice draft", status: "Private")
            }
        }
    }
}

struct EvidenceTile: View {
    let title: String
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(height: 120)
            Text(title)
                .font(.headline)
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PrivacyView: View {
    let policy: CapturePolicy

    var body: some View {
        Form {
            LabeledContent("Screenshot interval", value: "\(policy.screenshotIntervalMinutes) minutes")
            LabeledContent("Local-only screenshots", value: policy.localOnlyScreenshots ? "Enabled" : "Disabled")
            LabeledContent("Retention", value: "\(policy.retentionDays) days")
            LabeledContent("Excluded apps", value: policy.excludedApps.joined(separator: ", "))
        }
        .formStyle(.grouped)
    }
}

