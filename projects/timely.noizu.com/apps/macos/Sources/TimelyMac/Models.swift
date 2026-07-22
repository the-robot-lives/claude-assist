import Foundation

struct CapturePolicy {
    var screenshotIntervalMinutes: Int
    var localOnlyScreenshots: Bool
    var retentionDays: Int
    var excludedApps: [String]
}

struct CaptureInterval: Identifiable {
    let id = UUID()
    let start: String
    let end: String
    let project: String
    let task: String
    let state: IntervalState
    let confidence: Int
}

enum IntervalState: String, CaseIterable {
    case captured
    case overlap
    case inferred
    case idle
    case manual
    case `private`

    var label: String { rawValue.capitalized }
}

struct CaptureState {
    var isPaused: Bool
    var activeTask: String
    var syncStatus: String
    var unresolvedPrompts: Int
    var policy: CapturePolicy
    var intervals: [CaptureInterval]

    static let sample = CaptureState(
        isPaused: false,
        activeTask: "Timeline keyboard prototype",
        syncStatus: "Local buffer healthy",
        unresolvedPrompts: 3,
        policy: CapturePolicy(
            screenshotIntervalMinutes: 5,
            localOnlyScreenshots: true,
            retentionDays: 21,
            excludedApps: ["1Password", "Messages"]
        ),
        intervals: [
            CaptureInterval(start: "08:45", end: "10:05", project: "Timely Alpha", task: "Timeline keyboard prototype", state: .captured, confidence: 92),
            CaptureInterval(start: "10:05", end: "10:42", project: "Incident Review", task: "Deploy monitor and client update", state: .overlap, confidence: 81),
            CaptureInterval(start: "11:18", end: "11:52", project: "Idle", task: "Away from keyboard", state: .idle, confidence: 66),
            CaptureInterval(start: "12:20", end: "14:05", project: "Incident Review", task: "Root cause notes", state: .manual, confidence: 88)
        ]
    )
}

