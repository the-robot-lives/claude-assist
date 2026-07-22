import Foundation

enum CaptureMode: String, Codable {
    case idle
    case running
    case paused
    case pomodoroWork
    case pomodoroBreak

    var label: String {
        switch self {
        case .idle: "Ready"
        case .running: "Tracking"
        case .paused: "Paused"
        case .pomodoroWork: "Pomodoro focus"
        case .pomodoroBreak: "Pomodoro break"
        }
    }
}

enum SpanSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case timer
    case pomodoro

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct AppSettings: Codable {
    var screenshotIntervalMinutes: Double
    var screenshotCaptureEnabled: Bool
    var pomodoroWorkMinutes: Double
    var pomodoroBreakMinutes: Double
    var localOnlyScreenshots: Bool
    var retentionDays: Int
    var vision: VisionLLMSettings

    static let defaults = AppSettings(
        screenshotIntervalMinutes: 5,
        screenshotCaptureEnabled: false,
        pomodoroWorkMinutes: 25,
        pomodoroBreakMinutes: 5,
        localOnlyScreenshots: true,
        retentionDays: 0,
        vision: .defaults
    )

    init(
        screenshotIntervalMinutes: Double,
        screenshotCaptureEnabled: Bool,
        pomodoroWorkMinutes: Double,
        pomodoroBreakMinutes: Double,
        localOnlyScreenshots: Bool,
        retentionDays: Int,
        vision: VisionLLMSettings
    ) {
        self.screenshotIntervalMinutes = screenshotIntervalMinutes
        self.screenshotCaptureEnabled = screenshotCaptureEnabled
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroBreakMinutes = pomodoroBreakMinutes
        self.localOnlyScreenshots = localOnlyScreenshots
        self.retentionDays = retentionDays
        self.vision = vision
    }

    enum CodingKeys: String, CodingKey {
        case screenshotIntervalMinutes
        case screenshotCaptureEnabled
        case pomodoroWorkMinutes
        case pomodoroBreakMinutes
        case localOnlyScreenshots
        case retentionDays
        case vision
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaults
        screenshotIntervalMinutes = try values.decodeIfPresent(Double.self, forKey: .screenshotIntervalMinutes) ?? fallback.screenshotIntervalMinutes
        screenshotCaptureEnabled = try values.decodeIfPresent(Bool.self, forKey: .screenshotCaptureEnabled) ?? fallback.screenshotCaptureEnabled
        pomodoroWorkMinutes = try values.decodeIfPresent(Double.self, forKey: .pomodoroWorkMinutes) ?? fallback.pomodoroWorkMinutes
        pomodoroBreakMinutes = try values.decodeIfPresent(Double.self, forKey: .pomodoroBreakMinutes) ?? fallback.pomodoroBreakMinutes
        localOnlyScreenshots = try values.decodeIfPresent(Bool.self, forKey: .localOnlyScreenshots) ?? fallback.localOnlyScreenshots
        retentionDays = try values.decodeIfPresent(Int.self, forKey: .retentionDays) ?? fallback.retentionDays
        vision = try values.decodeIfPresent(VisionLLMSettings.self, forKey: .vision) ?? fallback.vision
    }
}

extension AppSettings {
    var retentionLabel: String {
        retentionDays <= 0 ? "Forever" : "\(retentionDays) days"
    }
}

struct VisionLLMSettings: Codable {
    var analysisEnabled: Bool
    var notifyOnProjectSwitch: Bool
    var provider: String
    var model: String
    var apiKey: String
    var baseURL: String
    var prompt: String
    var confidenceThreshold: Double

    static let providers = ["openai", "litellm", "ollama", "custom"]

    static let defaultModels: [String: String] = [
        "openai": "gpt-4o",
        "litellm": "gpt-4o",
        "ollama": "llama3.2-vision",
        "custom": "vision-model"
    ]

    static let defaultBaseURLs: [String: String] = [
        "openai": "https://api.openai.com/v1",
        "litellm": "https://inference.noizu.com/v1",
        "ollama": "http://localhost:11434",
        "custom": "https://api.example.com/v1"
    ]

    static let defaultAPIKeys: [String: String] = [
        "openai": "env: OPENAI_API_KEY",
        "litellm": "env: LITELLM_API_KEY",
        "ollama": "",
        "custom": "env: TIMELY_VISION_API_KEY"
    ]

    static let defaultPrompt = """
    You are Timely's private work-observation assistant. Review the screenshot and the known active time span, if provided. Return only JSON with these keys: status_update, inferred_project, inferred_task, project_switch_detected, confidence, evidence.

    Rules:
    - status_update is one concise sentence describing visible progress.
    - inferred_project is the project or client visible in the screenshot, or an empty string.
    - inferred_task is the current task visible in the screenshot, or an empty string.
    - project_switch_detected is true only when the screenshot appears to show a different project from the known project or prior inferred project.
    - confidence is a number from 0.0 to 1.0.
    - evidence is a short phrase naming the visible clues.
    """

    static let defaults = VisionLLMSettings(
        analysisEnabled: false,
        notifyOnProjectSwitch: true,
        provider: "openai",
        model: "gpt-4o",
        apiKey: "env: OPENAI_API_KEY",
        baseURL: "https://api.openai.com/v1",
        prompt: defaultPrompt,
        confidenceThreshold: 0.72
    )

    var effectiveModel: String {
        model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultModels[provider] ?? "vision-model"
            : model.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultBaseURLs[provider] ?? "https://api.example.com/v1"
            : baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveAPIKey: String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("env:") {
            let name = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            return TimelyEnvironmentResolver.resolve(name)
        }
        if !trimmed.isEmpty {
            return trimmed
        }
        guard let fallback = Self.defaultAPIKeys[provider], fallback.lowercased().hasPrefix("env:") else {
            return nil
        }
        let name = String(fallback.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        return TimelyEnvironmentResolver.resolve(name)
    }
}

struct VisionAnalysisRecord: Identifiable, Codable {
    var id: UUID
    var screenshotID: UUID
    var analyzedAt: Date
    var model: String
    var statusUpdate: String
    var inferredProject: String
    var inferredTask: String
    var projectSwitchDetected: Bool
    var confidence: Double
    var evidence: String
    var rawResponse: String
    var errorMessage: String?
}

struct TrackedTimeSpan: Identifiable, Codable {
    var id: UUID
    var title: String
    var project: String
    var start: Date
    var end: Date?
    var source: SpanSource
    var isBillable: Bool
    var notes: String

    var duration: TimeInterval {
        (end ?? Date()).timeIntervalSince(start)
    }

    var isOpen: Bool {
        end == nil
    }
}

struct ScreenshotRecord: Identifiable, Codable {
    var id: UUID
    var spanID: UUID?
    var capturedAt: Date
    var fileName: String
    var activeAppName: String
}

struct TimelySnapshot: Codable {
    var settings: AppSettings
    var spans: [TrackedTimeSpan]
    var screenshots: [ScreenshotRecord]
    var visionAnalyses: [VisionAnalysisRecord]
    var lastInferredProject: String?

    init(
        settings: AppSettings,
        spans: [TrackedTimeSpan],
        screenshots: [ScreenshotRecord],
        visionAnalyses: [VisionAnalysisRecord],
        lastInferredProject: String?
    ) {
        self.settings = settings
        self.spans = spans
        self.screenshots = screenshots
        self.visionAnalyses = visionAnalyses
        self.lastInferredProject = lastInferredProject
    }

    enum CodingKeys: String, CodingKey {
        case settings
        case spans
        case screenshots
        case visionAnalyses
        case lastInferredProject
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        settings = try values.decodeIfPresent(AppSettings.self, forKey: .settings) ?? .defaults
        spans = try values.decodeIfPresent([TrackedTimeSpan].self, forKey: .spans) ?? []
        screenshots = try values.decodeIfPresent([ScreenshotRecord].self, forKey: .screenshots) ?? []
        visionAnalyses = try values.decodeIfPresent([VisionAnalysisRecord].self, forKey: .visionAnalyses) ?? []
        lastInferredProject = try values.decodeIfPresent(String.self, forKey: .lastInferredProject)
    }
}

extension TimeInterval {
    var timelyClock: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
