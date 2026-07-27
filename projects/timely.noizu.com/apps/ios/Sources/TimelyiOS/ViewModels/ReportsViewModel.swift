import Foundation
import Observation
import TimelyKit

/// Range totals, from the server when it can be reached and from this device
/// when it cannot.
///
/// The two are **not** interchangeable and the screen never pretends otherwise.
/// Only the server sees every device's spans, and `weighted_billable_seconds`
/// depends on overlaps this device may not have pulled. A local rollup is
/// immediate feedback; a server summary is the number to invoice.
@MainActor
@Observable
final class ReportsViewModel {

    enum Preset: String, CaseIterable, Identifiable, Sendable {
        case today = "Today"
        case week = "This week"
        case month = "This month"
        case custom = "Custom"

        var id: String { rawValue }
    }

    enum Source: Sendable, Equatable {
        /// Straight from `GET /api/v1/reports/summary`.
        case server(generatedAt: Date)
        /// Computed here, from rows this device holds.
        case localFallback(reason: String)
    }

    var preset: Preset = .week {
        didSet { if preset != .custom { applyPreset() } }
    }

    private(set) var from: Date
    private(set) var to: Date
    var groupBy: ReportGroupKey = .client

    private(set) var summary: ReportSummary?
    private(set) var localRollup: DayRollup = .empty
    private(set) var localGroups: [LocalGroup] = []
    private(set) var source: Source = .localFallback(reason: "Not loaded yet.")
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// A local grouping, mirroring `ReportSummary.Group` closely enough that
    /// one row view renders either.
    struct LocalGroup: Identifiable, Sendable, Hashable {
        let label: String
        let parentLabel: String?
        let elapsed: TimeInterval
        let billable: TimeInterval
        let weightedBillable: TimeInterval
        let spanCount: Int
        var id: String { "\(parentLabel ?? "")/\(label)" }
    }

    private let calendar: Calendar

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        let week = calendar.dateInterval(of: .weekOfYear, for: now)
            ?? DateInterval(start: now, duration: 604_800)
        self.from = week.start
        self.to = week.end
    }

    var window: DateInterval {
        DateInterval(start: min(from, to), end: max(from, to))
    }

    var isServerBacked: Bool {
        if case .server = source { return true }
        return false
    }

    var sourceExplanation: String {
        switch source {
        case .server(let generatedAt):
            "Server totals, generated \(TimelyFormat.clock(generatedAt))."
        case .localFallback(let reason):
            "Totals from this device only. \(reason) "
                + "Another device's time for this range may be missing."
        }
    }

    /// Warnings that mean "do not invoice this range yet". Server-supplied when
    /// available; derived locally otherwise.
    var blockingWarnings: [ReportSummary.Warning] {
        summary?.blockingWarnings ?? []
    }

    var localWarningText: [String] {
        var warnings: [String] = []
        if localRollup.openSpanCount > 0 {
            warnings.append("\(localRollup.openSpanCount) interval(s) are still open.")
        }
        if localRollup.needsReviewCount > 0 {
            warnings.append("\(localRollup.needsReviewCount) interval(s) need review.")
        }
        if localRollup.hasContestedTime {
            warnings.append(
                "\(TimelyFormat.duration(localRollup.contestedBillable)) of billable time overlaps."
            )
        }
        return warnings
    }

    func setCustomRange(from newFrom: Date, to newTo: Date) {
        preset = .custom
        from = newFrom
        to = newTo
    }

    private func applyPreset(now: Date = Date()) {
        switch preset {
        case .today:
            let day = TimelyFormat.dayInterval(containing: now, calendar: calendar)
            from = day.start
            to = day.end
        case .week:
            let week = calendar.dateInterval(of: .weekOfYear, for: now)
                ?? DateInterval(start: now, duration: 604_800)
            from = week.start
            to = week.end
        case .month:
            let month = calendar.dateInterval(of: .month, for: now)
                ?? DateInterval(start: now, duration: 2_592_000)
            from = month.start
            to = month.end
        case .custom:
            break
        }
    }

    // MARK: - Loading

    func load(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        // Local first, always. It is fast, it cannot fail for network reasons,
        // and it means the screen is never empty while a request is in flight.
        await loadLocal(repository: repository, now: now)

        guard let api = environment.api else { return }
        do {
            let fetched = try await api.reportSummary(
                workspaceID: repository.context.workspaceID,
                from: window.start,
                to: window.end,
                groupBy: groupBy
            )
            summary = fetched
            source = .server(generatedAt: fetched.generatedAt)
        } catch let error as AuthError where error.requiresReauthentication {
            summary = nil
            source = .localFallback(reason: "You are signed out.")
        } catch {
            summary = nil
            source = .localFallback(reason: "The server could not be reached.")
        }
    }

    private func loadLocal(repository: TimelyRepository, now: Date) async {
        do {
            let spans = try await repository.spans(in: window)
            localRollup = LocalRollup.compute(spans: spans, window: window, now: now)

            let shares = LocalRollup.weightedShares(spans: spans, window: window, now: now)
            localGroups = Self.group(spans: spans, by: groupBy, window: window, shares: shares, now: now)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    static func group(
        spans: [TimeSpan],
        by key: ReportGroupKey,
        window: DateInterval,
        shares: [UUID: TimeInterval],
        now: Date
    ) -> [LocalGroup] {
        var buckets: [String: (parent: String?, elapsed: TimeInterval, billable: TimeInterval,
                              weighted: TimeInterval, count: Int)] = [:]

        for span in spans where !span.isDeleted {
            guard let clamped = LocalRollup.clamp(span, to: window, now: now) else { continue }

            let label: String
            var parent: String?
            switch key {
            case .client:
                label = span.clientName.isEmpty ? "Unassigned" : span.clientName
            case .project:
                label = span.projectName.isEmpty ? "Unassigned" : span.projectName
                parent = span.clientName.isEmpty ? nil : span.clientName
            case .ticket:
                label = span.ticketName.isEmpty ? "Unassigned" : span.ticketName
                parent = span.projectName.isEmpty ? nil : span.projectName
            case .day:
                label = TimelyFormat.dayTitle(span.start, relativeTo: now)
            case .source:
                label = span.source.label
            case .none:
                label = "All time"
            }

            var bucket = buckets[label] ?? (parent, 0, 0, 0, 0)
            bucket.parent = bucket.parent ?? parent
            bucket.elapsed += clamped.duration
            bucket.count += 1
            if span.isBillable {
                bucket.billable += clamped.duration
                bucket.weighted += shares[span.id] ?? clamped.duration
            }
            buckets[label] = bucket
        }

        return buckets
            .map {
                LocalGroup(
                    label: $0.key, parentLabel: $0.value.parent,
                    elapsed: $0.value.elapsed, billable: $0.value.billable,
                    weightedBillable: $0.value.weighted, spanCount: $0.value.count
                )
            }
            .sorted { $0.elapsed > $1.elapsed }
    }
}
