import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    TextField("Base URL", text: $settings.backendURLString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textContentType(.URL)

                    Text(settings.backendURL.host() ?? settings.backendURL.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Project") {
                    TextField("Project ID", text: $settings.projectId)
                        .textInputAutocapitalization(.never)
                        .textContentType(.none)
                }
            }
            .navigationTitle("Backend")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
