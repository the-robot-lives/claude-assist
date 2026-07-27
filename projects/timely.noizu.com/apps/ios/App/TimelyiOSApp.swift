import SwiftUI

/// The `.app` entry point.
///
/// Deliberately thin: everything it shows lives in the `TimelyiOS` package
/// sources, so the SwiftPM library and the shipped app are the same code and a
/// package-level test can drive any screen.
@main
struct TimelyiOSApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .task { await environment.bootstrap() }
        }
    }
}
