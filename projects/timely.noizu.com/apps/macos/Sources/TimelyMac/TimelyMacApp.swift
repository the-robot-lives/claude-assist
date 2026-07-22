import SwiftUI

@main
struct TimelyMacApp: App {
    @StateObject private var store = TimelyStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(minWidth: 1080, minHeight: 720)
        }
        .commands {
            CommandMenu("Capture") {
                Button("Start Span") {
                    store.startSpan()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button(store.mode == .paused ? "Resume Capture" : "Pause Capture") {
                    store.mode == .paused ? store.resume() : store.pause()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(store.activeSpanID == nil)

                Button("Stop Span") {
                    store.stopActiveSpan()
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
                .disabled(store.activeSpanID == nil)

                Divider()

                Button("Capture Screenshot Now") {
                    store.captureScreenshotNow()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Timely", systemImage: store.mode == .paused ? "pause.circle" : "timer") {
            MenuBarStatusView(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }
}
