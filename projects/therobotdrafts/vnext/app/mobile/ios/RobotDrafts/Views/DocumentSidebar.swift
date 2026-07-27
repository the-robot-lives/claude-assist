import SwiftUI

struct DocumentSidebar: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var documentsStore: DocumentsStore

    @Binding var selectedSummary: DocumentSummary?
    @Binding var showingSettings: Bool

    var body: some View {
        List(selection: $selectedSummary) {
            Section {
                Picker("Source", selection: $documentsStore.source) {
                    ForEach(DocumentSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    Task { await documentsStore.reload(projectId: settings.projectId) }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(documentsStore.isLoading)

                Button {
                    showingSettings = true
                } label: {
                    Label("Backend", systemImage: "server.rack")
                }
            }

            if !authStore.isSignedIn {
                Section("Session") {
                    LoginPanel()
                }
            } else {
                Section("Session") {
                    Label(authStore.user?.email ?? "Signed in", systemImage: "person.crop.circle.fill")
                    Button(role: .destructive) {
                        authStore.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }

            Section("Documents") {
                ForEach(documentsStore.documents) { document in
                    DocumentSummaryRow(summary: document)
                        .tag(document)
                }
            }
        }
        .navigationTitle("Robot Draft")
        .overlay {
            if documentsStore.documents.isEmpty && !documentsStore.isLoading {
                ContentUnavailableView("No Documents", systemImage: "doc.text.magnifyingglass")
            }
        }
        .refreshable {
            await documentsStore.reload(projectId: settings.projectId)
        }
        .onChange(of: documentsStore.source) { _, _ in
            Task {
                await documentsStore.reload(projectId: settings.projectId)
                selectedSummary = documentsStore.documents.first
            }
        }
    }
}

private struct DocumentSummaryRow: View {
    let summary: DocumentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.title)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 10) {
                Label("\(summary.nodeCount)", systemImage: "circle.hexagongrid")
                Label("\(summary.edgeCount)", systemImage: "arrow.triangle.branch")
                Text("v\(summary.version)")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
