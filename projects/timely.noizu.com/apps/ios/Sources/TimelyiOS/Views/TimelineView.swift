import SwiftUI
import TimelyKit

/// Browse and correct.
///
/// The desktop guide asks for a table; a phone gets a dense list with the same
/// columns folded into two lines. Selection exists for one reason — merge takes
/// N intervals — and it is opt-in so that tapping a row means "correct this"
/// rather than "start a multi-select I did not ask for".
struct TimelineView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = DayReviewViewModel()
    @State private var editing: TimeSpan?
    @State private var isSelecting = false
    @State private var mergePrimaryID: UUID?
    @State private var isPresentingMerge = false
    @State private var isPresentingSignIn = false
    @State private var mergeError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayBar

                List {
                    if model.visibleSpans.isEmpty {
                        Section {
                            EmptyStateRow(
                                message: model.searchText.isEmpty
                                    ? "Nothing recorded on this day."
                                    : "No intervals match “\(model.searchText)”.",
                                symbolName: "calendar"
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        Section {
                            ForEach(model.visibleSpans, id: \.id) { span in
                                row(for: span)
                            }
                        } header: {
                            Text(summaryLine)
                                .font(.caption)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.searchText, prompt: "Title, client, project")
            .refreshable {
                await environment.syncNow()
                await model.load(environment: environment)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isSelecting ? "Done" : "Select") {
                        isSelecting.toggle()
                        if !isSelecting { model.selection.removeAll() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Needs review only", isOn: $model.showOnlyNeedsReview)
                        Button("Go to today") { model.goToToday() }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                if isSelecting {
                    ToolbarItem(placement: .bottomBar) { mergeBar }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isSelecting {
                    SyncFooter()
                        .padding(.horizontal, TimelyTheme.Space.page)
                        .padding(.bottom, TimelyTheme.Space.compact)
                        .background(.bar)
                }
            }
        }
        .task(id: environment.phase) { await model.load(environment: environment) }
        .task(id: model.date) { await model.load(environment: environment) }
        .sheet(item: $editing) { span in
            SpanEditorView(span: span, evidence: model.evidence(for: span)) {
                Task { await model.load(environment: environment) }
            }
        }
        .sheet(isPresented: $isPresentingSignIn) { SignInView() }
        .confirmationDialog(
            "Keep which interval's details?",
            isPresented: $isPresentingMerge,
            titleVisibility: .visible
        ) {
            ForEach(model.selectedSpans, id: \.id) { span in
                Button(span.title.isEmpty ? "Untitled interval" : span.title) {
                    Task { await merge(keeping: span) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The merged interval keeps this one's title, client, project and billable "
                 + "setting, and spans the full range. Nothing is deleted — the originals are "
                 + "tombstoned and cited as its lineage.")
        }
        .alert("Could not merge", isPresented: .constant(mergeError != nil)) {
            Button("OK") { mergeError = nil }
        } message: {
            Text(mergeError ?? "")
        }
    }

    // MARK: - Pieces

    private var dayBar: some View {
        HStack(spacing: TimelyTheme.Space.group) {
            Button {
                model.move(byDays: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous day")

            VStack(spacing: 0) {
                Text(model.title)
                    .font(.subheadline.weight(.semibold))
                Text(TimelyFormat.duration(model.rollup.elapsed)
                     + " tracked · "
                     + TimelyFormat.decimalHours(model.rollup.weightedBillable) + "h billable")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            Button {
                model.move(byDays: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(model.isToday)
            .accessibilityLabel("Next day")
        }
        .padding(.horizontal, TimelyTheme.Space.page)
        .padding(.vertical, TimelyTheme.Space.compact)
        .background(.bar)
    }

    private var summaryLine: String {
        var parts = ["\(model.visibleSpans.count) interval(s)"]
        if model.rollup.openSpanCount > 0 {
            parts.append("\(model.rollup.openSpanCount) open")
        }
        if model.rollup.hasContestedTime {
            parts.append("\(TimelyFormat.duration(model.rollup.contestedBillable)) contested")
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func row(for span: TimeSpan) -> some View {
        HStack(spacing: TimelyTheme.Space.group) {
            if isSelecting {
                Image(systemName: model.selection.contains(span.id)
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(model.selection.contains(span.id)
                                     ? TimelyTheme.accent : .secondary)
                    .accessibilityHidden(true)
            }
            SpanRow(
                span: span,
                confidence: model.confidence(for: span),
                weightedSeconds: model.weighted(for: span)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                if model.selection.contains(span.id) {
                    model.selection.remove(span.id)
                } else {
                    model.selection.insert(span.id)
                }
            } else {
                editing = span
            }
        }
        .accessibilityAddTraits(isSelecting && model.selection.contains(span.id) ? .isSelected : [])
    }

    private var mergeBar: some View {
        HStack {
            Text("\(model.selection.count) selected")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Merge") {
                isPresentingMerge = true
            }
            .disabled(model.selection.count < 2)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func merge(keeping primary: TimeSpan) async {
        guard let repository = environment.repository else { return }
        let selected = model.selectedSpans

        switch SpanCorrection.merge(selected, keeping: primary, context: repository.context) {
        case .success(let plan):
            do {
                try await repository.apply(plan)
                model.selection.removeAll()
                isSelecting = false
                await environment.syncNow()
                await model.load(environment: environment)
            } catch {
                mergeError = String(describing: error)
            }
        case .failure(let error):
            mergeError = error.description
        }
    }
}
