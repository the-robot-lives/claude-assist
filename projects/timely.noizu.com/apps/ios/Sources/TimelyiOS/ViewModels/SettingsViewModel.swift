import Foundation
import Observation
import TimelyKit

/// Privacy, preferences, and an honest account of what this device is doing.
///
/// The screenshot gate is the important control here, and it is deliberately
/// presented as one half of a pair. Upload requires **both** the workspace
/// policy and this device to permit it (§7). A device toggle can only ever
/// tighten the result, never loosen the workspace's answer, and the screen
/// states which half is closed rather than showing a switch that appears to do
/// nothing.
@MainActor
@Observable
final class SettingsViewModel {

    private(set) var policy: WorkspacePolicy?
    private(set) var settings: UserSettings?
    private(set) var device: Device?
    private(set) var otherDevices: [Device] = []
    private(set) var syncCursor: SyncCursorState?

    private(set) var isLoading = false
    private(set) var isWorking = false
    private(set) var errorMessage: String?

    // MARK: - Derived privacy state

    /// This device's half of the gate. `local_only` true means "keep bytes
    /// here", so the opt-in is its inverse.
    var deviceAllowsScreenshotUpload: Bool {
        device.map { !$0.localOnlyScreenshots } ?? false
    }

    var workspaceAllowsScreenshotUpload: Bool {
        policy?.screenshotUploadAllowed ?? false
    }

    var gate: PrivacyGate {
        PrivacyGate(
            workspaceAllowsBlobUpload: workspaceAllowsScreenshotUpload,
            deviceOptedInToBlobUpload: deviceAllowsScreenshotUpload
        )
    }

    /// What actually happens to screenshot bytes, in one sentence.
    var gateExplanation: String {
        if !workspaceAllowsScreenshotUpload {
            return "This workspace does not allow screenshots to leave the device that captured "
                + "them. The switch below cannot override that."
        }
        if !deviceAllowsScreenshotUpload {
            return "Screenshots captured by your Mac stay on it. Turn this on to allow their "
                + "images to be uploaded to the workspace."
        }
        return "Screenshots captured by your Mac may be uploaded to the workspace. "
            + "Images the vision model flags as private are still never uploaded."
    }

    /// True while the device toggle would have no visible effect.
    var deviceToggleIsOverridden: Bool { !workspaceAllowsScreenshotUpload }

    /// Retention actually in force, given the workspace floor.
    var effectiveRetentionDescription: String {
        guard let settings, let policy else { return "Unknown" }
        let days = settings.effectiveRetentionDays(policy: policy)
        return days == 0 ? "Kept forever" : "\(days) days"
    }

    var visionRawResponseSyncs: Bool { policy?.syncVisionRawResponse ?? false }

    // MARK: - Loading

    func load(environment: AppEnvironment) async {
        guard let repository = environment.repository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            policy = try await repository.policy()
            settings = try await repository.userSettingsOrDefault()
            device = try await repository.deviceOrDefault(
                appVersion: environment.configuration.versionDescription,
                osVersion: environment.osVersion,
                name: environment.deviceName
            )
            otherDevices = try await repository.devices()
                .filter { $0.id != repository.context.deviceID && !$0.isRevoked }
            syncCursor = try await repository.syncState()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    // MARK: - Mutations

    /// Flip this device's half of the screenshot gate.
    ///
    /// Only the owning device may change its own row; the server rejects
    /// anything else with `not_device_owner`, so this write is always about
    /// *this* phone.
    func setDeviceAllowsScreenshotUpload(_ allowed: Bool, environment: AppEnvironment) async {
        guard let repository = environment.repository, var device else { return }
        guard device.localOnlyScreenshots == allowed else { return }

        device.localOnlyScreenshots = !allowed
        await write(environment: environment) {
            try await repository.saveDevice(device)
            self.device = device
        }
    }

    func setLocalOnlyScreenshots(_ localOnly: Bool, environment: AppEnvironment) async {
        guard let repository = environment.repository, var settings else { return }
        settings.localOnlyScreenshots = localOnly
        await write(environment: environment) {
            try await repository.saveUserSettings(settings)
            self.settings = settings
        }
    }

    func setIdleThresholdMinutes(_ minutes: Double, environment: AppEnvironment) async {
        guard let repository = environment.repository, var settings else { return }
        settings.idleThresholdMinutes = max(1, minutes)
        await write(environment: environment) {
            try await repository.saveUserSettings(settings)
            self.settings = settings
        }
    }

    func setRetentionDays(_ days: Int, environment: AppEnvironment) async {
        guard let repository = environment.repository, var settings else { return }
        settings.retentionDays = max(0, days)
        await write(environment: environment) {
            try await repository.saveUserSettings(settings)
            self.settings = settings
        }
    }

    func renameDevice(_ name: String, environment: AppEnvironment) async {
        guard let repository = environment.repository, var device else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != device.name else { return }

        device.name = trimmed
        await write(environment: environment) {
            try await repository.saveDevice(device)
            self.device = device
        }
    }

    private func write(environment: AppEnvironment, _ body: () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await body()
            await environment.refreshQueueDepth()
            await environment.syncNow()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func clearError() { errorMessage = nil }
}
