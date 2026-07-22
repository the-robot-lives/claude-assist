import SwiftUI

struct MenuBarStatusView: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Timely Capture")
                        .font(.headline)
                    Text(menuSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(store.mode == .paused ? .orange : store.activeSpanID == nil ? .secondary : .green)
                    .frame(width: 10, height: 10)
            }

            HStack {
                Button("Start") { store.startSpan() }
                    .disabled(store.currentTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(store.mode == .paused ? "Resume" : "Pause") {
                    store.mode == .paused ? store.resume() : store.pause()
                }
                .disabled(store.activeSpanID == nil)
                Button("Stop") { store.stopActiveSpan() }
                    .disabled(store.activeSpanID == nil)
            }

            Button("Capture screenshot now") {
                store.captureScreenshotNow()
            }

            Divider()

            Label("Tracked \(store.reviewedDuration.timelyClock)", systemImage: "clock")
            Label("\(store.screenshots.count) screenshots", systemImage: "camera")
            Label(store.settings.screenshotCaptureEnabled ? "Periodic capture on" : "Periodic capture off", systemImage: "repeat")

            if store.pomodoroRemaining > 0 {
                Label("Pomodoro \(store.pomodoroRemaining.timelyClock)", systemImage: "timer")
            }
        }
        .padding()
        .frame(width: 340)
    }

    private var menuSubtitle: String {
        if let active = store.activeSpan {
            return "\(active.title) / \(active.duration.timelyClock)"
        }
        return store.mode.label
    }
}

