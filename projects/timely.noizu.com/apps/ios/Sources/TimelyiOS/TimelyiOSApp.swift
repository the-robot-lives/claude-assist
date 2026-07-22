import SwiftUI

@main
struct TimelyiOSApp: App {
    @State private var store = TimelyStore.sample

    var body: some Scene {
        WindowGroup {
            RootView(store: $store)
        }
    }
}

