import SwiftUI
import TimelyKit

/// Decisions only the person who did the work can make.
///
/// A `suspected_duplicate` shows both intervals side by side with their
/// evidence, and offers three answers. A `billing_overlap` shows both and
/// offers two, because merging across clients would move billable time from one
/// to another. There is no button anywhere on this screen that resolves
/// anything in bulk.
struct ReviewQueueView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = ReviewQueueViewModel()
    @State private var editing: TimeSpan?

    var body: some View {
        NavigationStack {
            List {
                if model.items.isEmpty {
                    Section {
                        EmptyStateRow(
                            message: model.isLoading
                                ? "Loading…"
                                : "Nothing needs a decision right now.",
                            symbolName: "checkmark.circle"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if !model.judgementItems.isEmpty {
                    Section {
                        ForEach(model.judgementItems) { item in
                            judgementCard(item)
                        }
                    } header: {
                        Text("Your decision")
                    } footer: {
                        Text("Both records are kept until you choose. Timely never merges or "
                             + "removes billable time on its own.")
                    }
                }

                if !model.informationalItems.isEmpty {
                    Section("For your information") {
                        ForEach(model.informationalItems) { item in
                            informationalRow(item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Review")
            .refreshable {
                await environment.syncNow()
                await model.load(environment: environment)
            }
            .task(id: environment.phase) { await model.load(environment: environment) }
            .sheet(item: $editing) { span in
                SpanEditorView(span: span, evidence: .none) {
                    Task { await model.load(environment: environment) }
                }
            }
            .alert("Could not resolve", isPresented: .constant(model.errorMessage != nil)) {
                Button("OK") { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    // MARK: - Cards

    @ViewBuilder
    private func judgementCard(_ item: ReviewItem) -> some View {
        let pair = model.pair(for: item)

        VStack(alignment: .leading, spacing: TimelyTheme.Space.group) {
            Label(item.prompt, systemImage: item.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TimelyTheme.danger)

            if let detail = item.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let first = pair.0 { candidate(first) }
            if let second = pair.1 { candidate(second) }

            choices(for: item)
        }
        .padding(.vertical, TimelyTheme.Space.tight)
    }

    @ViewBuilder
    private func candidate(_ span: TimeSpan) -> some View {
        Button {
            editing = span
        } label: {
            VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
                HStack {
                    Text(span.title.isEmpty ? "Untitled interval" : span.title)
                        .font(.footnote.weight(.medium))
                    Spacer()
                    Text(TimelyFormat.duration(span.duration()))
                        .font(.footnote)
                        .monospacedDigit()
                }
                HStack(spacing: TimelyTheme.Space.compact) {
                    Text(TimelyFormat.range(start: span.start, end: span.end))
                    Text("·")
                    Text(TimelyFormat.taxonomyLabel(
                        client: span.clientName, project: span.projectName
                    ))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                HStack(spacing: TimelyTheme.Space.compact) {
                    StatusPill(ConfidenceState.derive(span: span))
                    if span.isBillable {
                        StatusPill(
                            label: "Billable", symbolName: "dollarsign.circle",
                            tint: TimelyTheme.success
                        )
                    }
                    Spacer(minLength: 0)
                    Text("Correct")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(TimelyTheme.accent)
                }
            }
            .padding(TimelyTheme.Space.group)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: TimelyTheme.buttonRadius, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func choices(for item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: TimelyTheme.Space.compact) {
            if item.code == .suspectedDuplicate, let first = model.span(item.spanID),
               let second = model.span(item.relatedSpanID) {
                Menu {
                    Button("Keep \(label(first))'s details") {
                        Task {
                            await model.mergePair(
                                item, keeping: first.id, environment: environment
                            )
                        }
                    }
                    Button("Keep \(label(second))'s details") {
                        Task {
                            await model.mergePair(
                                item, keeping: second.id, environment: environment
                            )
                        }
                    }
                } label: {
                    Label("They are the same — merge", systemImage: "arrow.triangle.merge")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack(spacing: TimelyTheme.Space.compact) {
                Button {
                    Task { await model.resolve(item, as: .dismissed, environment: environment) }
                } label: {
                    Text(item.code == .billingOverlap
                         ? "Both are correct" : "They are different")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    Task { await model.resolve(item, as: .accepted, environment: environment) }
                } label: {
                    Text("I have handled it")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func informationalRow(_ item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: TimelyTheme.Space.tight) {
            Label(item.prompt, systemImage: item.symbolName)
                .font(.subheadline)
            Text(item.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let detail = item.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: TimelyTheme.Space.compact) {
                if let span = model.span(item.spanID) {
                    Button("Open interval") { editing = span }
                        .font(.caption.weight(.medium))
                        .buttonStyle(.borderless)
                }
                if item.mutationID != nil {
                    Button("Dismiss") {
                        Task { await model.acknowledge(item, environment: environment) }
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderless)
                } else if item.code != nil {
                    Button("Mark handled") {
                        Task { await model.resolve(item, as: .accepted, environment: environment) }
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, TimelyTheme.Space.tight)
    }

    private func label(_ span: TimeSpan) -> String {
        span.title.isEmpty ? "the untitled interval" : span.title
    }
}
