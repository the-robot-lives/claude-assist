import SwiftUI
import TimelyKit

/// Correct one interval.
///
/// Everything the user might need in order to decide is on this screen: the
/// confidence label and why it says that, the evidence behind it, the flags
/// still open against it, and its lineage if it came from a split or a merge.
/// "Review beats recall" only works if the evidence is next to the edit.
struct SpanEditorView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var model: SpanEditorViewModel
    @State private var isConfirmingDelete = false
    @State private var isShowingSplit = false

    private let onChange: () -> Void

    init(span: TimeSpan, evidence: SpanEvidence, onChange: @escaping () -> Void = {}) {
        _model = State(initialValue: SpanEditorViewModel(span: span, evidence: evidence))
        self.onChange = onChange
    }

    var body: some View {
        NavigationStack {
            Form {
                confidenceSection

                if !model.pendingReasons.isEmpty {
                    flagsSection
                }

                detailsSection
                timesSection
                evidenceSection

                if !model.lineage.isEmpty {
                    lineageSection
                }

                actionsSection
            }
            .navigationTitle("Correct interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.save(environment: environment)
                            if model.didFinish { onChange(); dismiss() }
                        }
                    }
                    .disabled(!model.hasChanges || model.isWorking || model.isLocked)
                }
            }
            .disabled(model.isWorking)
            .alert("Could not save", isPresented: .constant(model.errorMessage != nil)) {
                Button("OK") { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
            .confirmationDialog(
                "Delete this interval?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await model.delete(environment: environment)
                        if model.didFinish { onChange(); dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The interval is marked deleted and stops counting towards your totals. "
                     + "Nothing is destroyed — it stays in the record and can be recovered on "
                     + "the web.")
            }
        }
    }

    // MARK: - Sections

    private var confidenceSection: some View {
        Section {
            HStack(spacing: TimelyTheme.Space.group) {
                StatusPill(model.confidence)
                Spacer()
                Text(TimelyFormat.duration(model.duration))
                    .font(.headline)
                    .monospacedDigit()
            }
            Text(model.confidence.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if model.isLocked {
                Label(
                    "This interval is locked and cannot be changed.",
                    systemImage: "lock"
                )
                .font(.caption)
                .foregroundStyle(TimelyTheme.warning)
            }
        }
    }

    private var flagsSection: some View {
        Section("Needs your decision") {
            ForEach(Array(model.pendingReasons.enumerated()), id: \.offset) { _, reason in
                VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
                    Text(reason.code.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline.weight(.medium))
                    if let detail = reason.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Raised by \(reason.raisedBy.rawValue) · "
                         + TimelyFormat.clock(reason.raisedAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Answer these in Review. Nothing here resolves them for you.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Title", text: $model.title, axis: .vertical)
                .lineLimit(1...3)
            TextField("Client", text: $model.clientName)
                .textInputAutocapitalization(.words)
            TextField("Project", text: $model.projectName)
                .textInputAutocapitalization(.words)
            TextField("Ticket", text: $model.ticketName)
            Toggle("Billable", isOn: $model.isBillable)
            TextField("Notes", text: $model.notes, axis: .vertical)
                .lineLimit(2...6)
        }
        .disabled(model.isLocked)
    }

    private var timesSection: some View {
        Section("Time") {
            DatePicker("Start", selection: $model.start)

            if let end = model.end {
                DatePicker(
                    "End",
                    selection: Binding(get: { end }, set: { model.end = $0 })
                )
            } else {
                HStack {
                    Text("End")
                    Spacer()
                    Text("Still running")
                        .foregroundStyle(.secondary)
                }
                Button("Close this interval now") {
                    Task {
                        await model.close(environment: environment)
                        if model.didFinish { onChange(); dismiss() }
                    }
                }
            }
        }
        .disabled(model.isLocked)
    }

    private var evidenceSection: some View {
        Section("Evidence") {
            if model.evidence.isEmpty {
                Text("No screenshots or analysis reached this device for this interval.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                DetailRow(
                    label: "Screenshots",
                    value: "\(model.evidence.screenshots.count)",
                    symbolName: "photo"
                )
                if !model.evidence.censored.isEmpty {
                    DetailRow(
                        label: "Removed as private",
                        value: "\(model.evidence.censored.count)",
                        symbolName: "eye.slash"
                    )
                }
                if let strongest = model.evidence.strongestAnalysis {
                    DetailRow(
                        label: "Model confidence",
                        value: TimelyFormat.percent(strongest.confidence),
                        symbolName: "gauge.with.dots.needle.33percent"
                    )
                }
                ForEach(model.evidence.recallLines, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                // The image bytes are not here and are not requested. A
                // companion's recall surface is metadata plus the analysis
                // summary, which is the normal case rather than a degraded one.
                Text("Images stay on the device that captured them.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var lineageSection: some View {
        Section("History") {
            Text("This interval came from \(model.lineage.count) earlier one(s), "
                 + "kept in the record for audit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                isShowingSplit = true
            } label: {
                Label("Split into two", systemImage: "scissors")
            }
            .disabled(model.isLocked)

            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("Delete interval", systemImage: "trash")
            }
            .disabled(model.isLocked)
        }
        .sheet(isPresented: $isShowingSplit) {
            SplitSheet(model: model) {
                onChange()
                dismiss()
            }
        }
    }
}

/// Choosing where to cut.
private struct SplitSheet: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @Bindable var model: SpanEditorViewModel
    let onSplit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Cut at") {
                    DatePicker(
                        "Split point",
                        selection: $model.splitPoint,
                        in: splitRange,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                }

                Section {
                    DetailRow(
                        label: "First part",
                        value: TimelyFormat.duration(
                            model.splitPoint.timeIntervalSince(model.start)
                        )
                    )
                    DetailRow(
                        label: "Second part",
                        value: model.end.map {
                            TimelyFormat.duration($0.timeIntervalSince(model.splitPoint))
                        } ?? "Still running"
                    )
                } footer: {
                    Text("Both halves are created citing this interval, and this interval is "
                         + "marked deleted — all in one batch, so it either lands whole or not "
                         + "at all.")
                }
            }
            .navigationTitle("Split interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Split") {
                        Task {
                            await model.split(environment: environment)
                            if model.didFinish { dismiss(); onSplit() }
                        }
                    }
                    .disabled(!model.canSplit || model.isWorking)
                }
            }
        }
    }

    private var splitRange: ClosedRange<Date> {
        let lower = model.start.addingTimeInterval(60)
        let upper = (model.end ?? Date()).addingTimeInterval(-60)
        return lower <= upper ? lower...upper : lower...lower
    }
}
