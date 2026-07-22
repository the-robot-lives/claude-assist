import SwiftUI

@main
struct TimelyiOSApp: App {
    @State private var store = TimelyStore.empty

    var body: some Scene {
        WindowGroup {
            RootView(store: $store)
        }
    }
}
