import Foundation

struct TimelyStore {
    var paused: Bool
    var summary: TimelySummary
    var intervals: [TimelyInterval]
    var prompts: [IdlePrompt]
    var reports: [ClientReport]
    var policy: TimelyPolicy

    static let sample = TimelyStore(
        paused: false,
        summary: TimelySummary(reviewedHours: 6.4, billableHours: 5.75, confidence: 87, unresolvedPrompts: 3),
        intervals: [
            TimelyInterval(start: "08:45", end: "10:05", project: "Timely Alpha", task: "Timeline keyboard prototype", state: .captured, confidence: 92),
            TimelyInterval(start: "10:05", end: "10:42", project: "Incident Review", task: "Deploy monitor and client update", state: .overlap, confidence: 81),
            TimelyInterval(start: "10:31", end: "11:18", project: "Dashboard Polish", task: "Visual QA pass", state: .inferred, confidence: 74),
            TimelyInterval(start: "11:18", end: "11:52", project: "Idle", task: "Away from keyboard", state: .idle, confidence: 66),
            TimelyInterval(start: "12:20", end: "14:05", project: "Incident Review", task: "Root cause notes", state: .manual, confidence: 88)
        ],
        prompts: [
            IdlePrompt(window: "11:18-11:52", suggestion: "Discard idle time", reason: "No input, screen locked"),
            IdlePrompt(window: "15:12-15:31", suggestion: "Resume Dashboard Polish", reason: "Returned to same document")
        ],
        reports: [
            ClientReport(client: "Aster Systems", hours: 3.05, confidence: 84, evidence: "selected screenshots"),
            ClientReport(client: "HelioWorks", hours: 2.7, confidence: 77, evidence: "metadata only")
        ],
        policy: TimelyPolicy(screenshotIntervalMinutes: 5, localOnlyScreenshots: true, retentionDays: 21, excludedApps: ["1Password", "Messages"])
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

