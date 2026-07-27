import SwiftUI
import TimelyKit

/// Add an interval by hand.
///
/// Fields follow the desktop guide's Manual Entry rule — title, project and
/// client, start, end, billable state, notes, add action — in that order, so
/// someone who uses both surfaces is filling in the same form.
struct ManualEntryView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var model: ManualEntryViewModel
    private let onSave: () -> Void

    init(gap: IdleGap? = nil, onSave: @escaping () -> Void = {}) {
        _model = State(initialValue: gap.map(ManualEntryViewModel.init(fillingGap:))
                       ?? ManualEntryViewModel())
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What") {
                    TextField("Title", text: $model.title, axis: .vertical)
                        .lineLimit(1...3)
                    picker(
                        label: "Client", text: $model.clientName, options: model.knownClients
                    )
                    picker(
                        label: "Project", text: $model.projectName, options: model.knownProjects
                    )
                    TextField("Ticket", text: $model.ticketName)
                }

                Section("When") {
                    DatePicker("Start", selection: $model.start)
                    Toggle("Still running", isOn: $model.leaveOpen)
                    if !model.leaveOpen {
                        DatePicker("End", selection: $model.end)
                    }
                    DetailRow(
                        label: "Duration",
                        value: TimelyFormat.duration(model.duration),
                        symbolName: "clock"
                    )
                }

                Section {
                    Toggle("Billable", isOn: $model.isBillable)
                    TextField("Notes", text: $model.notes, axis: .vertical)
                        .lineLimit(2...6)
                } footer: {
                    Text("Manual intervals are labelled as such everywhere they appear. "
                         + "They carry no captured evidence, and the app never implies they do.")
                }
            }
            .navigationTitle("New interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await model.save(environment: environment)
                            if model.didFinish { onSave(); dismiss() }
                        }
                    }
                    .disabled(!model.canSave)
                }
            }
            .disabled(model.isWorking)
            .task { await model.loadSuggestions(environment: environment) }
            .alert("Could not add interval", isPresented: .constant(model.errorMessage != nil)) {
                Button("OK") { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    /// Free text with suggestions rather than a closed picker: the taxonomy
    /// vivifies from names, so typing a new client is a supported act, not an
    /// error to be prevented.
    @ViewBuilder
    private func picker(label: String, text: Binding<String>, options: [String]) -> some View {
        HStack {
            TextField(label, text: text)
                .textInputAutocapitalization(.words)
            if !options.isEmpty {
                Menu {
                    ForEach(options.prefix(30), id: \.self) { option in
                        Button(option) { text.wrappedValue = option }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Choose an existing \(label.lowercased())")
            }
        }
    }
}
