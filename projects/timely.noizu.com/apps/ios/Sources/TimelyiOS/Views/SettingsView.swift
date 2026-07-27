import SwiftUI
import TimelyKit

/// Privacy, preferences, devices, and account.
///
/// The screenshot gate leads, because it is the control the product's trust
/// story rests on. It is presented as two halves — workspace and device — with
/// the effective answer stated in words, so a switch that cannot take effect
/// says why instead of appearing broken.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = SettingsViewModel()
    @State private var session = SessionViewModel()
    @State private var isPresentingSignIn = false
    @State private var deviceName = ""

    var body: some View {
        NavigationStack {
            List {
                privacySection
                capturePreferencesSection
                deviceSection
                syncSection
                accountSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .refreshable { await model.load(environment: environment) }
            .task(id: environment.phase) {
                await model.load(environment: environment)
                deviceName = model.device?.name ?? ""
            }
            .sheet(isPresented: $isPresentingSignIn) { SignInView() }
            .alert("Could not save", isPresented: .constant(model.errorMessage != nil)) {
                Button("OK") { model.clearError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This app never captures anything")
                        .font(.subheadline.weight(.medium))
                    Text("No screenshots, no background recording, no always-on timer. "
                         + "It reviews what your Mac captured.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(TimelyTheme.success)
            }

            Toggle(
                "Allow screenshot images to be uploaded",
                isOn: Binding(
                    get: { model.deviceAllowsScreenshotUpload },
                    set: { allowed in
                        Task {
                            await model.setDeviceAllowsScreenshotUpload(
                                allowed, environment: environment
                            )
                        }
                    }
                )
            )
            .disabled(model.deviceToggleIsOverridden || model.isWorking)

            DetailRow(
                label: "Workspace policy",
                value: model.workspaceAllowsScreenshotUpload ? "Upload allowed" : "Upload blocked",
                symbolName: model.workspaceAllowsScreenshotUpload ? "building.2" : "lock.building"
            )
            DetailRow(
                label: "Effective",
                value: model.gate.isOpen ? "Images may upload" : "Images stay on the Mac",
                symbolName: model.gate.isOpen ? "icloud.and.arrow.up" : "lock.icloud"
            )
        } header: {
            Text("Screenshots")
        } footer: {
            Text(model.gateExplanation)
        }
    }

    private var capturePreferencesSection: some View {
        Section {
            if let settings = model.settings {
                DetailRow(
                    label: "Idle threshold",
                    value: "\(Int(settings.idleThresholdMinutes)) min",
                    symbolName: "moon.zzz"
                )
                Stepper(
                    "Adjust idle threshold",
                    value: Binding(
                        get: { settings.idleThresholdMinutes },
                        set: { minutes in
                            Task {
                                await model.setIdleThresholdMinutes(
                                    minutes, environment: environment
                                )
                            }
                        }
                    ),
                    in: 1...120,
                    step: 1
                )
                .labelsHidden()

                DetailRow(
                    label: "Screenshot retention",
                    value: model.effectiveRetentionDescription,
                    symbolName: "clock.arrow.circlepath"
                )
                DetailRow(
                    label: "Model transcriptions sync",
                    value: model.visionRawResponseSyncs ? "Yes" : "No, kept on the Mac",
                    symbolName: "text.viewfinder"
                )
            } else {
                Text("Preferences have not synced to this device yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Capture policy")
        } footer: {
            Text("These govern what your Mac captures and how long it is kept. "
                 + "Your workspace sets a floor; you can be stricter, never looser.")
        }
    }

    // MARK: - Devices

    private var deviceSection: some View {
        Section {
            HStack {
                TextField("Device name", text: $deviceName)
                    .onSubmit {
                        Task { await model.renameDevice(deviceName, environment: environment) }
                    }
                Spacer()
                StatusPill(label: "Companion", symbolName: "iphone", tint: .secondary)
            }

            ForEach(model.otherDevices, id: \.id) { device in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name.isEmpty ? "Unnamed device" : device.name)
                            .font(.subheadline)
                        Text(device.platform.rawValue + " · " + device.appVersion)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if device.isCaptureAgent {
                        StatusPill(
                            label: "Capture", symbolName: "camera.viewfinder",
                            tint: TimelyTheme.accent
                        )
                    }
                }
            }
        } header: {
            Text("Devices")
        } footer: {
            Text("Only a Mac can capture. This device is registered as a companion and cannot "
                 + "claim otherwise.")
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        Section {
            DetailRow(
                label: "Last synced",
                value: environment.status.lastSyncedAt.map { TimelyFormat.clock($0) } ?? "Never",
                symbolName: "arrow.triangle.2.circlepath"
            )
            DetailRow(
                label: "Waiting to upload",
                value: "\(environment.status.queuedMutations)",
                symbolName: "tray.and.arrow.up"
            )
            if let cursor = model.syncCursor {
                DetailRow(
                    label: "Sync position",
                    value: "\(cursor.cursor)",
                    symbolName: "number"
                )
            }
            Button {
                Task { await environment.syncNow() }
            } label: {
                Label("Sync now", systemImage: "arrow.clockwise")
            }
            .disabled(environment.status.isSyncing)
        } header: {
            Text("Sync")
        } footer: {
            Text("Everything works without a connection. Queued changes upload on their own; "
                 + "nothing is lost while you are offline.")
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            switch environment.status.session {
            case .none:
                Button("Sign in") { isPresentingSignIn = true }
            case .expired:
                Label("Your session expired", systemImage: "person.badge.key")
                    .foregroundStyle(TimelyTheme.warning)
                Button("Sign in again") { isPresentingSignIn = true }
            case .active:
                Label("Signed in", systemImage: "checkmark.circle")
                    .foregroundStyle(TimelyTheme.success)
                Button("Sign out", role: .destructive) {
                    Task { await session.signOut(environment: environment) }
                }
            }
        } header: {
            Text("Account")
        } footer: {
            Text(environment.isUsingProvisionalWorkspace
                 ? "Your records are held under a local workspace. Signing in moves them to your "
                    + "real workspace — nothing is lost."
                 : "Signing out keeps every record on this device, along with anything waiting "
                    + "to upload.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            DetailRow(
                label: "Version",
                value: environment.configuration.versionDescription,
                symbolName: "info.circle"
            )
            DetailRow(
                label: "Server",
                value: environment.configuration.baseURL.host() ?? "—",
                symbolName: "server.rack"
            )
        }
    }
}
