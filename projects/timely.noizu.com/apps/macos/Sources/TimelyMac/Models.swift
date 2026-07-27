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

// `SpanSource`, `TimeSpan`, `Screenshot`, `VisionAnalysis`,
// `CensoredScreenshot`, `ClientRecord`, `ProjectRecord` and `TicketRecord`
// now come from TimelyKit. They used to be declared here, a second time, and
// a third time on iOS — which is exactly how the same three model sets drifted
// apart in billing.noizu.com. The only types left in this file are the ones
// that are genuinely device-local: the capture agent's own settings (which
// carry a vision API key the contract deliberately has no field for) and the
// menu-bar capture mode.


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
        screenshotCaptureEnabled: true,
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
    var privacyRedactionEnabled: Bool
    var notifyOnCensoredScreenshot: Bool
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
    - Also return privacy_sensitive, privacy_category, and privacy_action.
    - privacy_sensitive is true if the screenshot visibly contains secrets, API keys, passwords, private email, personal chat, adult material, financial or identity records, medical details, or other private material that should not be retained as evidence.
    - privacy_category is one of none, secret, private_email, personal_chat, adult_material, financial, identity, medical, other_private.
    - privacy_action is keep when privacy_sensitive is false, or censor when privacy_sensitive is true.
    """

    static let defaults = VisionLLMSettings(
        analysisEnabled: false,
        notifyOnProjectSwitch: true,
        privacyRedactionEnabled: true,
        notifyOnCensoredScreenshot: true,
        provider: "openai",
        model: "gpt-4o",
        apiKey: "env: OPENAI_API_KEY",
        baseURL: "https://api.openai.com/v1",
        prompt: defaultPrompt,
        confidenceThreshold: 0.72
    )

    init(
        analysisEnabled: Bool,
        notifyOnProjectSwitch: Bool,
        privacyRedactionEnabled: Bool,
        notifyOnCensoredScreenshot: Bool,
        provider: String,
        model: String,
        apiKey: String,
        baseURL: String,
        prompt: String,
        confidenceThreshold: Double
    ) {
        self.analysisEnabled = analysisEnabled
        self.notifyOnProjectSwitch = notifyOnProjectSwitch
        self.privacyRedactionEnabled = privacyRedactionEnabled
        self.notifyOnCensoredScreenshot = notifyOnCensoredScreenshot
        self.provider = provider
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.prompt = prompt
        self.confidenceThreshold = confidenceThreshold
    }

    enum CodingKeys: String, CodingKey {
        case analysisEnabled
        case notifyOnProjectSwitch
        case privacyRedactionEnabled
        case notifyOnCensoredScreenshot
        case provider
        case model
        case apiKey
        case baseURL
        case prompt
        case confidenceThreshold
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaults
        analysisEnabled = try values.decodeIfPresent(Bool.self, forKey: .analysisEnabled) ?? fallback.analysisEnabled
        notifyOnProjectSwitch = try values.decodeIfPresent(Bool.self, forKey: .notifyOnProjectSwitch) ?? fallback.notifyOnProjectSwitch
        privacyRedactionEnabled = try values.decodeIfPresent(Bool.self, forKey: .privacyRedactionEnabled) ?? fallback.privacyRedactionEnabled
        notifyOnCensoredScreenshot = try values.decodeIfPresent(Bool.self, forKey: .notifyOnCensoredScreenshot) ?? fallback.notifyOnCensoredScreenshot
        provider = try values.decodeIfPresent(String.self, forKey: .provider) ?? fallback.provider
        model = try values.decodeIfPresent(String.self, forKey: .model) ?? fallback.model
        apiKey = try values.decodeIfPresent(String.self, forKey: .apiKey) ?? fallback.apiKey
        baseURL = try values.decodeIfPresent(String.self, forKey: .baseURL) ?? fallback.baseURL
        prompt = try values.decodeIfPresent(String.self, forKey: .prompt) ?? fallback.prompt
        confidenceThreshold = try values.decodeIfPresent(Double.self, forKey: .confidenceThreshold) ?? fallback.confidenceThreshold
    }

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
