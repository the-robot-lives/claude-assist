import SwiftUI

@main
struct RobotDraftsApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var authStore: AuthStore
    @StateObject private var documentsStore: DocumentsStore

    init() {
        let settings = AppSettings()
        let tokenStore = KeychainTokenStore()
        let apiClient = APIClient(baseURL: settings.backendURL)

        _settings = StateObject(wrappedValue: settings)
        _authStore = StateObject(wrappedValue: AuthStore(apiClient: apiClient, tokenStore: tokenStore))
        _documentsStore = StateObject(wrappedValue: DocumentsStore(apiClient: apiClient, tokenStore: tokenStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(authStore)
                .environmentObject(documentsStore)
        }
    }
}
