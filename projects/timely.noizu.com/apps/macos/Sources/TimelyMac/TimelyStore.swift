import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class TimelyStore: ObservableObject {
    @Published var settings: AppSettings = .defaults
    @Published var spans: [TrackedTimeSpan] = []
    @Published var screenshots: [ScreenshotRecord] = []
    @Published var visionAnalyses: [VisionAnalysisRecord] = []
    @Published var censoredScreenshots: [CensoredScreenshotRecord] = []
    @Published var isAnalyzingVisionScreenshot: Bool = false
    @Published var lastInferredProject: String?
    @Published var mode: CaptureMode = .idle
    @Published var activeSpanID: UUID?
    @Published var currentTask: String = ""
    @Published var currentProject: String = ""
    @Published var manualTitle: String = ""
    @Published var manualProject: String = ""
    @Published var manualStart: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    @Published var manualEnd: Date = Date()
    @Published var manualNotes: String = ""
    @Published var manualBillable: Bool = true
    @Published var now: Date = Date()
    @Published var pomodoroRemaining: TimeInterval = 0
    @Published var lastError: String?
    @Published var lastScreenshotAt: Date?

    private var tickTimer: Timer?
    private var screenshotTimer: Timer?
    private var pomodoroWorkSpanID: UUID?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        load()
        startClock()
        configureScreenshotTimer()
        requestNotificationPermissionIfNeeded()
    }

    var activeSpan: TrackedTimeSpan? {
        guard let activeSpanID else { return nil }
        return spans.first { $0.id == activeSpanID }
    }

    var reviewedDuration: TimeInterval {
        spans.reduce(0) { total, span in total + span.duration }
    }

    var billableDuration: TimeInterval {
        spans.filter(\.isBillable).reduce(0) { total, span in total + span.duration }
    }

    var appSupportURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("Timely", isDirectory: true)
    }

    var screenshotsURL: URL {
        appSupportURL.appendingPathComponent("Screenshots", isDirectory: true)
    }

    private var snapshotURL: URL {
        appSupportURL.appendingPathComponent("timely-state.json")
    }

    func startSpan() {
        let trimmedTask = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a task before starting a span."
            return
        }

        closeActiveSpan()

        let span = TrackedTimeSpan(
            id: UUID(),
            title: trimmedTask,
            project: currentProject.trimmingCharacters(in: .whitespacesAndNewlines),
            start: Date(),
            end: nil,
            source: .timer,
            isBillable: true,
            notes: ""
        )

        spans.insert(span, at: 0)
        activeSpanID = span.id
        mode = .running
        lastError = nil
        save()
        configureScreenshotTimer()
    }

    func pause() {
        guard mode == .running || mode == .pomodoroWork else { return }
        mode = .paused
        stopScreenshotTimer()
        save()
    }

    func resume() {
        guard activeSpanID != nil else {
            startSpan()
            return
        }
        mode = pomodoroWorkSpanID == activeSpanID ? .pomodoroWork : .running
        configureScreenshotTimer()
        save()
    }

    func stopActiveSpan() {
        closeActiveSpan()
        activeSpanID = nil
        pomodoroWorkSpanID = nil
        mode = .idle
        pomodoroRemaining = 0
        stopScreenshotTimer()
        save()
    }

    func addManualSpan() {
        let trimmedTask = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a title before adding a manual span."
            return
        }
        guard manualEnd > manualStart else {
            lastError = "Manual span end must be after start."
            return
        }

        let span = TrackedTimeSpan(
            id: UUID(),
            title: trimmedTask,
            project: manualProject.trimmingCharacters(in: .whitespacesAndNewlines),
            start: manualStart,
            end: manualEnd,
            source: .manual,
            isBillable: manualBillable,
            notes: manualNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        spans.insert(span, at: 0)
        manualTitle = ""
        manualProject = ""
        manualNotes = ""
        manualEnd = Date()
        manualStart = Calendar.current.date(byAdding: .hour, value: -1, to: manualEnd) ?? manualEnd
        lastError = nil
        save()
    }

    func deleteSpan(_ span: TrackedTimeSpan) {
        if activeSpanID == span.id {
            activeSpanID = nil
            mode = .idle
        }
        spans.removeAll { $0.id == span.id }
        save()
    }

    func startPomodoro() {
        let trimmedTask = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a Pomodoro task first."
            return
        }

        closeActiveSpan()

        let span = TrackedTimeSpan(
            id: UUID(),
            title: trimmedTask,
            project: currentProject.trimmingCharacters(in: .whitespacesAndNewlines),
            start: Date(),
            end: nil,
            source: .pomodoro,
            isBillable: true,
            notes: "Pomodoro focus span"
        )

        spans.insert(span, at: 0)
        activeSpanID = span.id
        pomodoroWorkSpanID = span.id
        pomodoroRemaining = settings.pomodoroWorkMinutes * 60
        mode = .pomodoroWork
        lastError = nil
        save()
        configureScreenshotTimer()
    }

    func completePomodoroNow() {
        closeActiveSpan()
        activeSpanID = nil
        pomodoroWorkSpanID = nil
        pomodoroRemaining = settings.pomodoroBreakMinutes * 60
        mode = .pomodoroBreak
        stopScreenshotTimer()
        save()
    }

    func finishBreak() {
        pomodoroRemaining = 0
        mode = .idle
        save()
    }

    func captureScreenshotNow() {
        do {
            let record = try captureScreenshot()
            screenshots.insert(record, at: 0)
            lastScreenshotAt = record.capturedAt
            save()
            analyzeScreenshotIfConfigured(record)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func analyzeLatestScreenshot() async {
        guard let screenshot = screenshots.first else {
            lastError = "Capture a screenshot before running vision analysis."
            return
        }
        await analyzeScreenshot(screenshot, force: true)
    }

    func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func openScreenshotsFolder() {
        ensureDirectories()
        NSWorkspace.shared.open(screenshotsURL)
    }

    func settingsChanged() {
        save()
        configureScreenshotTimer()
    }

    func load() {
        ensureDirectories()
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else { return }
        do {
            let data = try Data(contentsOf: snapshotURL)
            let snapshot = try decoder.decode(TimelySnapshot.self, from: data)
            settings = snapshot.settings
            spans = snapshot.spans.sorted { $0.start > $1.start }
            screenshots = snapshot.screenshots.sorted { $0.capturedAt > $1.capturedAt }
            visionAnalyses = snapshot.visionAnalyses.sorted { $0.analyzedAt > $1.analyzedAt }
            censoredScreenshots = snapshot.censoredScreenshots.sorted { $0.censoredAt > $1.censoredAt }
            lastInferredProject = snapshot.lastInferredProject
        } catch {
            lastError = "Could not load saved Timely state: \(error.localizedDescription)"
        }
    }

    func save() {
        ensureDirectories()
        do {
            let snapshot = TimelySnapshot(
                settings: settings,
                spans: spans,
                screenshots: screenshots,
                visionAnalyses: visionAnalyses,
                censoredScreenshots: censoredScreenshots,
                lastInferredProject: lastInferredProject
            )
            let data = try encoder.encode(snapshot)
            try data.write(to: snapshotURL, options: .atomic)
        } catch {
            lastError = "Could not save Timely state: \(error.localizedDescription)"
        }
    }

    private func startClock() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        now = Date()
        guard mode == .pomodoroWork || mode == .pomodoroBreak else { return }

        pomodoroRemaining = max(0, pomodoroRemaining - 1)
        if pomodoroRemaining == 0 {
            if mode == .pomodoroWork {
                completePomodoroNow()
            } else {
                finishBreak()
            }
        }
    }

    private func closeActiveSpan() {
        guard let activeSpanID,
              let index = spans.firstIndex(where: { $0.id == activeSpanID }),
              spans[index].end == nil else { return }
        spans[index].end = Date()
    }

    private func configureScreenshotTimer() {
        stopScreenshotTimer()
        guard settings.screenshotCaptureEnabled,
              mode == .running || mode == .pomodoroWork,
              settings.screenshotIntervalMinutes > 0 else { return }

        screenshotTimer = Timer.scheduledTimer(withTimeInterval: settings.screenshotIntervalMinutes * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureScreenshotNow()
            }
        }
    }

    private func analyzeScreenshotIfConfigured(_ screenshot: ScreenshotRecord) {
        guard settings.vision.analysisEnabled else { return }
        Task { @MainActor in
            await analyzeScreenshot(screenshot, force: false)
        }
    }

    private func analyzeScreenshot(_ screenshot: ScreenshotRecord, force: Bool) async {
        if !force && visionAnalyses.contains(where: { $0.screenshotID == screenshot.id }) {
            return
        }

        isAnalyzingVisionScreenshot = true
        defer { isAnalyzingVisionScreenshot = false }

        let client = VisionLLMClient(settings: settings.vision)
        let screenshotURL = screenshotsURL.appendingPathComponent(screenshot.fileName)
        let context = VisionAnalysisContext(
            knownTask: activeSpan?.title ?? currentTask,
            knownProject: activeSpan?.project ?? currentProject,
            activeAppName: screenshot.activeAppName,
            previousInferredProject: lastInferredProject,
            capturedAt: screenshot.capturedAt
        )

        do {
            var analysis = try await client.analyze(
                screenshotID: screenshot.id,
                screenshotURL: screenshotURL,
                context: context
            )
            if analysis.projectSwitchDetected && analysis.confidence < settings.vision.confidenceThreshold {
                analysis.projectSwitchDetected = false
            }
            if settings.vision.privacyRedactionEnabled && analysis.privacySensitive {
                censorScreenshot(screenshot, analysis: analysis)
                return
            }
            recordVisionAnalysis(analysis)
        } catch {
            let failed = VisionAnalysisRecord(
                id: UUID(),
                screenshotID: screenshot.id,
                analyzedAt: Date(),
                model: settings.vision.effectiveModel,
                statusUpdate: "Vision analysis failed.",
                inferredProject: "",
                inferredTask: "",
                projectSwitchDetected: false,
                confidence: 0,
                evidence: "",
                privacySensitive: false,
                privacyCategory: "none",
                rawResponse: "",
                errorMessage: error.localizedDescription
            )
            recordVisionAnalysis(failed)
            lastError = error.localizedDescription
        }
    }

    private func recordVisionAnalysis(_ analysis: VisionAnalysisRecord) {
        visionAnalyses.removeAll { $0.screenshotID == analysis.screenshotID }
        visionAnalyses.insert(analysis, at: 0)
        visionAnalyses = Array(visionAnalyses.prefix(200))

        if !analysis.inferredProject.isEmpty {
            lastInferredProject = analysis.inferredProject
        }

        if settings.vision.notifyOnProjectSwitch && analysis.projectSwitchDetected {
            sendProjectSwitchNotification(analysis)
        }
        save()
    }

    private func censorScreenshot(_ screenshot: ScreenshotRecord, analysis: VisionAnalysisRecord) {
        let screenshotURL = screenshotsURL.appendingPathComponent(screenshot.fileName)
        var deletedLocalFile = false
        if FileManager.default.fileExists(atPath: screenshotURL.path) {
            do {
                try FileManager.default.removeItem(at: screenshotURL)
                deletedLocalFile = true
            } catch {
                lastError = "Sensitive screenshot was detached, but the local file could not be deleted: \(error.localizedDescription)"
            }
        } else {
            deletedLocalFile = true
        }

        screenshots.removeAll { $0.id == screenshot.id }
        visionAnalyses.removeAll { $0.screenshotID == screenshot.id }

        let record = CensoredScreenshotRecord(
            id: UUID(),
            screenshotID: screenshot.id,
            spanID: screenshot.spanID,
            fileName: screenshot.fileName,
            activeAppName: screenshot.activeAppName,
            capturedAt: screenshot.capturedAt,
            censoredAt: Date(),
            model: analysis.model,
            category: analysis.privacyCategory.isEmpty ? "other_private" : analysis.privacyCategory,
            reason: analysis.evidence.isEmpty ? "Vision LLM identified private screenshot content." : analysis.evidence,
            confidence: analysis.confidence,
            deletedLocalFile: deletedLocalFile
        )
        censoredScreenshots.insert(record, at: 0)
        censoredScreenshots = Array(censoredScreenshots.prefix(200))

        if settings.vision.notifyOnCensoredScreenshot {
            sendCensoredScreenshotNotification(record)
        }
        save()
    }

    private func requestNotificationPermissionIfNeeded() {
        guard settings.vision.notifyOnProjectSwitch || settings.vision.notifyOnCensoredScreenshot else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
        }
    }

    private func sendProjectSwitchNotification(_ analysis: VisionAnalysisRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Timely detected a project switch"
        let project = analysis.inferredProject.isEmpty ? "another project" : analysis.inferredProject
        content.body = "It looks like you switched to \(project). \(analysis.statusUpdate)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timely-project-switch-\(analysis.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendCensoredScreenshotNotification(_ record: CensoredScreenshotRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Timely censored a screenshot"
        content.body = "A \(record.category.replacingOccurrences(of: "_", with: " ")) screenshot was removed from evidence history."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timely-censored-\(record.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func stopScreenshotTimer() {
        screenshotTimer?.invalidate()
        screenshotTimer = nil
    }

    private func captureScreenshot() throws -> ScreenshotRecord {
        ensureDirectories()
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw TimelyError.screenshotUnavailable
        }

        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw TimelyError.screenshotEncodingFailed
        }

        let capturedAt = Date()
        let fileName = "timely-\(Self.fileStampFormatter.string(from: capturedAt)).png"
        let url = screenshotsURL.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)

        return ScreenshotRecord(
            id: UUID(),
            spanID: activeSpanID,
            capturedAt: capturedAt,
            fileName: fileName,
            activeAppName: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown app"
        )
    }

    private func ensureDirectories() {
        try? FileManager.default.createDirectory(at: screenshotsURL, withIntermediateDirectories: true)
    }

    private static let fileStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

enum TimelyError: LocalizedError {
    case screenshotUnavailable
    case screenshotEncodingFailed

    var errorDescription: String? {
        switch self {
        case .screenshotUnavailable:
            "Screenshot capture failed. Grant Screen Recording permission to Timely in System Settings and try again."
        case .screenshotEncodingFailed:
            "Screenshot capture succeeded, but PNG encoding failed."
        }
    }
}
