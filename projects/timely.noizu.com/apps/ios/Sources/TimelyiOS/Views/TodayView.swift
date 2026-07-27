import SwiftUI
import TimelyKit

/// The Daily Review flow, on one screen.
///
/// UX brief order: open the day, resolve idle gaps and low-confidence
/// intervals, correct, then submit. The metrics sit above the list because they
/// are what tells the user whether the day is finished; the list is what they
/// act on.
struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = DayReviewViewModel()
    @State private var editing: TimeSpan?
    @State private var isPresentingManualEntry = false
    @State private var isPresentingSignIn = false

    var onReviewCountChange: (Int) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TimelyTheme.Space.card) {
                    SyncStatusBanner(isPresentingSignIn: $isPresentingSignIn)

                    metrics

                    if !model.unresolvedIdleGaps.isEmpty {
                        idleSummary
                    }

                    if model.pendingJudgementCount > 0 {
                        judgementSummary
                    }

                    SectionHeading(
                        "Intervals",
                        detail: model.spans.isEmpty
                            ? nil
                            : "\(model.spans.count) today · tap to correct"
                    ) {
                        Toggle("Needs review", isOn: $model.showOnlyNeedsReview)
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .font(.caption)
                    }

                    if model.visibleSpans.isEmpty {
                        EmptyStateRow(
                            message: model.showOnlyNeedsReview
                                ? "Nothing today needs review."
                                : "No time recorded today yet.",
                            symbolName: model.showOnlyNeedsReview ? "checkmark.circle" : "clock",
                            actionTitle: model.showOnlyNeedsReview ? nil : "Add an interval",
                            action: model.showOnlyNeedsReview ? nil : { isPresentingManualEntry = true }
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(model.visibleSpans, id: \.id) { span in
                                Button {
                                    editing = span
                                } label: {
                                    SpanRow(
                                        span: span,
                                        confidence: model.confidence(for: span),
                                        weightedSeconds: model.weighted(for: span)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, TimelyTheme.Space.card)
                                .padding(.vertical, TimelyTheme.Space.compact)

                                if span.id != model.visibleSpans.last?.id {
                                    Divider().padding(.leading, TimelyTheme.Space.card)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: TimelyTheme.radius, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    SyncFooter()
                }
                .padding(TimelyTheme.Space.page)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(model.title)
            .refreshable {
                await environment.syncNow()
                await model.load(environment: environment)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingManualEntry = true
                    } label: {
                        Label("Add interval", systemImage: "plus")
                    }
                }
            }
        }
        .task(id: environment.phase) { await model.load(environment: environment) }
        .onChange(of: model.pendingJudgementCount) { _, count in onReviewCountChange(count) }
        .sheet(item: $editing) { span in
            SpanEditorView(span: span, evidence: model.evidence(for: span)) {
                Task { await model.load(environment: environment) }
            }
        }
        .sheet(isPresented: $isPresentingManualEntry) {
            ManualEntryView {
                Task { await model.load(environment: environment) }
            }
        }
        .sheet(isPresented: $isPresentingSignIn) {
            SignInView()
        }
    }

    // MARK: - Pieces

    private var metrics: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: TimelyTheme.Space.group),
                      GridItem(.flexible(), spacing: TimelyTheme.Space.group)],
            spacing: TimelyTheme.Space.group
        ) {
            MetricTile(
                label: "Tracked",
                value: TimelyFormat.duration(model.rollup.elapsed),
                detail: "\(model.rollup.spanCount) interval(s)",
                symbolName: "clock"
            )
            MetricTile(
                label: "Billable",
                value: TimelyFormat.decimalHours(model.rollup.weightedBillable),
                detail: model.rollup.hasContestedTime
                    ? "hours · \(TimelyFormat.duration(model.rollup.contestedBillable)) contested"
                    : "hours, overlap-adjusted",
                symbolName: "dollarsign.circle",
                tint: model.rollup.hasContestedTime ? TimelyTheme.warning : TimelyTheme.success
            )
            MetricTile(
                label: "Needs review",
                value: "\(model.rollup.needsReviewCount)",
                detail: model.rollup.needsReviewCount == 0 ? "nothing pending" : "intervals flagged",
                symbolName: "exclamationmark.triangle",
                tint: model.rollup.needsReviewCount == 0 ? .primary : TimelyTheme.danger
            )
            MetricTile(
                label: "Unaccounted",
                value: TimelyFormat.duration(
                    model.unresolvedIdleGaps.reduce(0) { $0 + $1.duration }
                ),
                detail: "\(model.unresolvedIdleGaps.count) gap(s)",
                symbolName: "moon.zzz",
                tint: model.unresolvedIdleGaps.isEmpty ? .primary : TimelyTheme.warning
            )
        }
    }

    private var idleSummary: some View {
        NavigationLink {
            IdleReviewView()
        } label: {
            NoticeBanner(
                title: "\(model.unresolvedIdleGaps.count) gap(s) to account for",
                message: "Time between intervals that nothing explains. Assign it, or say it "
                    + "was not work.",
                symbolName: "moon.zzz",
                tint: TimelyTheme.warning
            )
        }
        .buttonStyle(.plain)
    }

    private var judgementSummary: some View {
        NavigationLink {
            ReviewQueueView()
        } label: {
            NoticeBanner(
                title: "\(model.pendingJudgementCount) decision(s) waiting",
                message: "Two records claim some of the same time. Nothing is merged or removed "
                    + "until you say so.",
                symbolName: "exclamationmark.triangle",
                tint: TimelyTheme.danger
            )
        }
        .buttonStyle(.plain)
    }
}

