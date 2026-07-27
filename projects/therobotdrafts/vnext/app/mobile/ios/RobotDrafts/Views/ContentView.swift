import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var documentsStore: DocumentsStore

    @State private var selectedSummary: DocumentSummary?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            DocumentSidebar(
                selectedSummary: $selectedSummary,
                showingSettings: $showingSettings
            )
        } detail: {
            DocumentDetailView(document: documentsStore.selectedDocument)
        }
        .tint(Brand.primary)
        .preferredColorScheme(.dark)
        .background(Brand.page)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .onChange(of: selectedSummary) { _, summary in
            guard let summary else { return }
            Task { await documentsStore.select(summary) }
        }
        .onChange(of: settings.backendURLString) { _, _ in
            authStore.updateBackendURL(settings.backendURL)
            documentsStore.updateBackendURL(settings.backendURL)
        }
        .task {
            authStore.updateBackendURL(settings.backendURL)
            documentsStore.updateBackendURL(settings.backendURL)
            await documentsStore.reload(projectId: settings.projectId)
            selectedSummary = documentsStore.documents.first
        }
    }
}
