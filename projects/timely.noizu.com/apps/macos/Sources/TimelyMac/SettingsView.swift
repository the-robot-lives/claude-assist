import SwiftUI
import TimelyKit

struct SettingsView: View {
    @ObservedObject var store: TimelyStore
    @State private var retentionMode: RetentionMode = .forever

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Preferences",
                    title: "Settings",
                    subtitle: "Tune capture cadence, evidence storage, Pomodoro timing, Vision LLM behavior, and local state."
                ) {
                    HStack {
                        if store.isAnalyzingVisionScreenshot {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Button("Analyze latest", systemImage: "sparkle.magnifyingglass") {
                            Task { await store.analyzeLatestScreenshot() }
                        }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                        .disabled(store.screenshots.isEmpty || store.isAnalyzingVisionScreenshot)
                        Button("Open screenshots", systemImage: "folder") {
                            store.openScreenshotsFolder()
                        }
                        .buttonStyle(TimelySecondaryButtonStyle())
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    ScreenshotSettingsCard(store: store, retentionMode: $retentionMode)
                    PomodoroSettingsCard(store: store)
                }

                HStack(alignment: .top, spacing: 16) {
                    VisionConfigCard(store: store)
                    VStack(alignment: .leading, spacing: 16) {
                        VisionResultCard(store: store)
                        CensoredHistoryCard(store: store)
                    }
                }

                StorageSettingsCard(store: store)
            }
            .frame(maxWidth: 1240, alignment: .topLeading)
        }
        .onAppear {
            retentionMode = store.settings.retentionDays <= 0 ? .forever : .days
        }
    }
}

private enum RetentionMode: String, CaseIterable, Identifiable {
    case forever = "Forever"
    case days = "Timed"

    var id: String { rawValue }
}

private struct ScreenshotSettingsCard: View {
    @ObservedObject var store: TimelyStore
    @Binding var retentionMode: RetentionMode

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Screenshot capture", systemImage: "camera")
                .font(.headline)

            Toggle("Enable periodic screenshots", isOn: $store.settings.screenshotCaptureEnabled)
                .onChange(of: store.settings.screenshotCaptureEnabled) { store.settingsChanged() }

            Stepper(
                "Screenshot interval: \(Int(store.settings.screenshotIntervalMinutes)) minutes",
                value: $store.settings.screenshotIntervalMinutes,
                in: 1...60,
                step: 1
            )
            .onChange(of: store.settings.screenshotIntervalMinutes) { store.settingsChanged() }

            Toggle("Store screenshots locally only", isOn: $store.settings.localOnlyScreenshots)
                .onChange(of: store.settings.localOnlyScreenshots) { store.settingsChanged() }

            Picker("Retention", selection: $retentionMode) {
                ForEach(RetentionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: retentionMode) {
                if retentionMode == .forever {
                    store.settings.retentionDays = 0
                } else if store.settings.retentionDays <= 0 {
                    store.settings.retentionDays = 365
                }
                store.settingsChanged()
            }

            if retentionMode == .days {
                Stepper("Keep screenshots: \(store.settings.retentionDays) days", value: $store.settings.retentionDays, in: 1...3650)
                    .onChange(of: store.settings.retentionDays) { store.settingsChanged() }
            } else {
                LabeledContent("Keep screenshots", value: "Forever")
                    .font(.callout)
            }
        }
        .timelyCard()
    }
}

private struct PomodoroSettingsCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Pomodoro", systemImage: "timer")
                .font(.headline)

            Stepper("Focus: \(Int(store.settings.pomodoroWorkMinutes)) minutes", value: $store.settings.pomodoroWorkMinutes, in: 5...120, step: 5)
                .onChange(of: store.settings.pomodoroWorkMinutes) { store.settingsChanged() }

            Stepper("Break: \(Int(store.settings.pomodoroBreakMinutes)) minutes", value: $store.settings.pomodoroBreakMinutes, in: 1...60, step: 1)
                .onChange(of: store.settings.pomodoroBreakMinutes) { store.settingsChanged() }
        }
        .timelyCard()
    }
}

private struct StorageSettingsCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Storage", systemImage: "internaldrive")
                .font(.headline)

            LabeledContent("Retention", value: store.settings.retentionLabel)
            LabeledContent("State file", value: store.appSupportURL.appendingPathComponent("timely-state.json").path)
            LabeledContent("Screenshots", value: store.screenshotsURL.path)
        }
        .font(.callout)
        .timelyCard()
    }
}

private struct CensoredHistoryCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Censored history", systemImage: "eye.slash")
                    .font(.headline)
                Spacer()
                TimelyStatusPill(title: "\(store.censoredScreenshots.count)", systemImage: "shield", tint: TimelyTheme.warning)
            }

            if store.censoredScreenshots.isEmpty {
                EmptyStateView(message: "No screenshots have been censored.")
            } else {
                ForEach(Array(store.censoredScreenshots.prefix(6))) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(record.censoredAt.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                            Spacer()
                            TimelyStatusPill(
                                title: record.deletedLocalFile ? "Deleted" : "Detached",
                                systemImage: record.deletedLocalFile ? "trash" : "paperclip.badge.ellipsis",
                                tint: record.deletedLocalFile ? TimelyTheme.success : TimelyTheme.warning
                            )
                        }
                        Text(record.category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.body.weight(.medium))
                        Text(record.reason)
                            .font(.caption)
                            .foregroundStyle(TimelyTheme.secondaryText)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 6)
                    if record.id != store.censoredScreenshots.prefix(6).last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }
}
