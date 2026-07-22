import SwiftUI

struct MenuBarStatusView: View {
    @Binding var captureState: CaptureState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Timely Capture")
                        .font(.headline)
                    Text(captureState.isPaused ? "Paused" : captureState.activeTask)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(captureState.isPaused ? .orange : .green)
                    .frame(width: 10, height: 10)
            }

            Button(captureState.isPaused ? "Resume capture" : "Pause capture") {
                captureState.isPaused.toggle()
            }
            .buttonStyle(.borderedProminent)

            Divider()

            Label("\(captureState.unresolvedPrompts) unresolved prompts", systemImage: "questionmark.bubble")
            Label(captureState.syncStatus, systemImage: "externaldrive")
            Label("\(captureState.policy.screenshotIntervalMinutes)m screenshot interval", systemImage: "camera")
        }
        .padding()
        .frame(width: 320)
    }
}

