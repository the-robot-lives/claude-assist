import Foundation

/// `GET /api/v1/reports/summary` — the server's date-range rollup.
///
/// The server is authoritative for anything that gets invoiced. A companion may
/// compute a local rollup from its own store for immediate feedback while
/// offline, but the two are not interchangeable: only the server sees every
/// device's spans, and `weightedBillableSeconds` depends on overlaps this
/// device may not have pulled yet.
public struct ReportSummary: Sendable, Hashable, Decodable {

    public struct Range: Sendable, Hashable, Decodable {
        public let from: Date
        public let to: Date
        public let timeZone: String

        enum CodingKeys: String, CodingKey {
            case from, to
            case timeZone = "time_zone"
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            from = try c.decode(Date.self, forKey: .from)
            to = try c.decode(Date.self, forKey: .to)
            timeZone = try c.value(.timeZone, or: "UTC")
        }
    }

    public struct Totals: Sendable, Hashable, Decodable {
        public let elapsedSeconds: Int
        public let billableSeconds: Int
        public let nonBillableSeconds: Int

        /// Billable seconds after overlapping spans are de-weighted, so two
        /// concurrent timers on the same hour do not bill it twice. This is the
        /// number an invoice should use.
        public let weightedBillableSeconds: Int

        public let spanCount: Int
        public let needsReviewCount: Int

        /// Fraction of spans backed by at least one vision analysis, 0...1.
        public let evidenceCoverage: Double

        enum CodingKeys: String, CodingKey {
            case elapsedSeconds = "elapsed_seconds"
            case billableSeconds = "billable_seconds"
            case nonBillableSeconds = "non_billable_seconds"
            case weightedBillableSeconds = "weighted_billable_seconds"
            case spanCount = "span_count"
            case needsReviewCount = "needs_review_count"
            case evidenceCoverage = "evidence_coverage"
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            elapsedSeconds = try c.value(.elapsedSeconds, or: 0)
            billableSeconds = try c.value(.billableSeconds, or: 0)
            nonBillableSeconds = try c.value(.nonBillableSeconds, or: 0)
            weightedBillableSeconds = try c.value(.weightedBillableSeconds, or: 0)
            spanCount = try c.value(.spanCount, or: 0)
            needsReviewCount = try c.value(.needsReviewCount, or: 0)
            evidenceCoverage = try c.value(.evidenceCoverage, or: 0)
        }
    }

    public struct Group: Sendable, Hashable, Decodable {
        public let key: ReportGroupKey
        public let keyID: UUID?
        public let label: String
        public let parentLabel: String?
        public let elapsedSeconds: Int
        public let billableSeconds: Int
        public let weightedBillableSeconds: Int
        public let spanCount: Int
        public let evidenceCoverage: Double

        enum CodingKeys: String, CodingKey {
            case key, label
            case keyID = "key_id"
            case parentLabel = "parent_label"
            case elapsedSeconds = "elapsed_seconds"
            case billableSeconds = "billable_seconds"
            case weightedBillableSeconds = "weighted_billable_seconds"
            case spanCount = "span_count"
            case evidenceCoverage = "evidence_coverage"
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            key = try c.contractEnum(.key, or: .none)
            keyID = try c.decodeOptionalUUID(.keyID)
            label = try c.value(.label, or: "")
            parentLabel = try c.optional(.parentLabel)
            elapsedSeconds = try c.value(.elapsedSeconds, or: 0)
            billableSeconds = try c.value(.billableSeconds, or: 0)
            weightedBillableSeconds = try c.value(.weightedBillableSeconds, or: 0)
            spanCount = try c.value(.spanCount, or: 0)
            evidenceCoverage = try c.value(.evidenceCoverage, or: 0)
        }
    }

    /// Something about the range a human should see before invoicing it.
    public struct Warning: Sendable, Hashable, Decodable {
        public let code: ReportWarningCode
        public let message: String
        public let count: Int

        enum CodingKeys: String, CodingKey {
            case code, message, count
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            code = try c.contractEnum(.code, or: .unknown)
            message = try c.value(.message, or: "")
            count = try c.value(.count, or: 0)
        }
    }

    public let range: Range
    public let groupBy: ReportGroupKey
    public let totals: Totals
    public let groups: [Group]
    public let warnings: [Warning]
    public let generatedAt: Date
    public let serverRevision: Int64

    enum CodingKeys: String, CodingKey {
        case range, totals, groups, warnings
        case groupBy = "group_by"
        case generatedAt = "generated_at"
        case serverRevision = "server_revision"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        range = try c.decode(Range.self, forKey: .range)
        groupBy = try c.contractEnum(.groupBy, or: .none)
        totals = try c.decode(Totals.self, forKey: .totals)
        groups = try c.value(.groups, or: [])
        warnings = try c.value(.warnings, or: [])
        generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
        serverRevision = try c.value(.serverRevision, or: Int64(0))
    }

    /// Warnings that mean "do not invoice this range yet".
    public var blockingWarnings: [Warning] {
        warnings.filter {
            $0.code == .billingOverlap
                || $0.code == .suspectedDuplicate
                || $0.code == .openSpans
        }
    }
}
