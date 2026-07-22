import SwiftUI

@main
struct TimelyMacApp: App {
    @State private var captureState = CaptureState.sample

    var body: some Scene {
        WindowGroup {
            ContentView(captureState: $captureState)
                .frame(minWidth: 920, minHeight: 620)
        }
        .commands {
            CommandMenu("Capture") {
                Button(captureState.isPaused ? "Resume Capture" : "Pause Capture") {
                    captureState.isPaused.toggle()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Timely", systemImage: captureState.isPaused ? "pause.circle" : "record.circle") {
            MenuBarStatusView(captureState: $captureState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(policy: $captureState.policy)
        }
    }
}

