import Foundation

struct TimelyStore {
    var paused: Bool
    var summary: TimelySummary
    var intervals: [TimelyInterval]
    var prompts: [IdlePrompt]
    var reports: [ClientReport]
    var policy: TimelyPolicy

    static let empty = TimelyStore(
        paused: false,
        summary: TimelySummary(reviewedHours: 0, billableHours: 0, confidence: 0, unresolvedPrompts: 0),
        intervals: [],
        prompts: [],
        reports: [],
        policy: TimelyPolicy(screenshotIntervalMinutes: 0, localOnlyScreenshots: false, retentionDays: 0, excludedApps: [])
    )
}

struct TimelySummary {
    let reviewedHours: Double
    let billableHours: Double
    let confidence: Int
    let unresolvedPrompts: Int
}

struct TimelyInterval: Identifiable {
    let id = UUID()
    let start: String
    let end: String
    let project: String
    let task: String
    let state: IntervalState
    let confidence: Int
}

enum IntervalState: String {
    case captured = "Captured"
    case overlap = "Overlap"
    case inferred = "Inferred"
    case idle = "Idle"
    case manual = "Manual"
    case `private` = "Private"
}

struct IdlePrompt: Identifiable {
    let id = UUID()
    let window: String
    let suggestion: String
    let reason: String
}

struct ClientReport: Identifiable {
    let id = UUID()
    let client: String
    let hours: Double
    let confidence: Int
    let evidence: String
}

struct TimelyPolicy {
    var screenshotIntervalMinutes: Int
    var localOnlyScreenshots: Bool
    var retentionDays: Int
    var excludedApps: [String]
}
