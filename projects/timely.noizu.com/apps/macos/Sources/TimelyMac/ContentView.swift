import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: TimelyStore
    @State private var selectedSection: TimelySection = .today

    var body: some View {
        NavigationSplitView {
            List(TimelySection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
                    .font(.system(size: 13, weight: .medium))
            }
            .listStyle(.sidebar)
            .navigationTitle("Timely")
            .frame(minWidth: 190)
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
                Group {
                    switch selectedSection {
                    case .today:
                        TodayScreen(store: store)
                    case .work:
                        WorkScreen(store: store)
                    case .clients:
                        ClientsScreen(store: store)
                    case .settings:
                        SettingsView(store: store)
                    }
                }
                .padding(TimelyTheme.pagePadding)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(store.mode == .paused ? "Resume" : "Pause", systemImage: store.mode == .paused ? "play.fill" : "pause.fill") {
                    store.mode == .paused ? store.resume() : store.pause()
                }
                .disabled(store.activeSpanID == nil)
            }
            ToolbarItem {
                Button("Screenshot", systemImage: "camera") {
                    store.captureScreenshotNow()
                }
            }
        }
    }
}

enum TimelySection: String, CaseIterable, Identifiable {
    case today
    case work
    case clients
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .work: "Work"
        case .clients: "Clients"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today: "rectangle.grid.2x2"
        case .work: "rectangle.3.group"
        case .clients: "folder.badge.person.crop"
        case .settings: "slider.horizontal.3"
        }
    }
}

enum WorkTab: String, CaseIterable, Identifiable {
    case capture = "Capture"
    case manual = "Manual Entry"
    case timeline = "Timeline"

    var id: String { rawValue }
}

enum CapturePanelMode: String, CaseIterable, Identifiable {
    case live = "Live"
    case pomodoro = "Pomodoro"

    var id: String { rawValue }
}

enum DirectoryTab: String, CaseIterable, Identifiable {
    case clients = "Clients"
    case projects = "Projects"
    case tickets = "Tickets"

    var id: String { rawValue }
}

enum TodayDetailTab: String, CaseIterable, Identifiable {
    case activity = "Activity"
    case evidence = "Evidence"
    case ai = "AI"

    var id: String { rawValue }
}

struct TodayScreen: View {
    @ObservedObject var store: TimelyStore
    @State private var selectedDetail: TodayDetailTab = .activity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Desktop Agent",
                    title: "Today",
                    subtitle: store.activeSpan.map { "\($0.title) has been active for \($0.duration.timelyClock)." } ?? "Set the work, start the clock, and let evidence collect quietly."
                ) {
                    StatusIndicator(store: store)
                }

                if let error = store.lastError {
                    ErrorBanner(message: error)
                }

                FocusSessionCard(store: store)

                TodayStatusStrip(store: store)

                TodayDetailTabs(store: store, selectedTab: $selectedDetail)
            }
            .frame(maxWidth: 960, alignment: .topLeading)
        }
    }
}

struct FocusSessionCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(store.mode.label, systemImage: modeSymbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(modeTint)
                    Text(store.activeSpan?.title ?? "What are you working on?")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .lineLimit(2)
                    Text(activeAssignment)
                        .font(.callout)
                        .foregroundStyle(TimelyTheme.secondaryText)
                }
                Spacer()
                Text(store.activeSpan?.duration.timelyClock ?? "00:00")
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.72)
            }

            if store.activeSpan == nil {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TimelyTheme.secondaryText)
                            TextField("e.g. Implement timeline review", text: $store.currentTask)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Client")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TimelyTheme.secondaryText)
                            TextField("e.g. Noizu", text: $store.currentClient)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    GridRow {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Project")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TimelyTheme.secondaryText)
                            TextField("e.g. timely.noizu.com", text: $store.currentProject)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ticket")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TimelyTheme.secondaryText)
                            TextField("e.g. TIM-124", text: $store.currentTicket)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                if store.activeSpan == nil {
                    Button("Start", systemImage: "play.fill") { store.startSpan() }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                }
                Button(store.mode == .paused ? "Resume" : "Pause", systemImage: store.mode == .paused ? "play.fill" : "pause.fill") {
                    store.mode == .paused ? store.resume() : store.pause()
                }
                .buttonStyle(TimelySecondaryButtonStyle())
                .disabled(store.activeSpanID == nil)
                Button("Stop", systemImage: "stop.fill") { store.stopActiveSpan() }
                    .buttonStyle(TimelySecondaryButtonStyle())
                    .disabled(store.activeSpanID == nil)
                Spacer()
                Button {
                    store.captureScreenshotNow()
                } label: {
                    Image(systemName: "camera")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(TimelyIconButtonStyle())
                .help("Capture screenshot now")
            }
        }
        .timelyCard(padding: 20)
    }

    private var modeTint: Color {
        switch store.mode {
        case .idle: TimelyTheme.secondaryText
        case .running, .pomodoroWork: TimelyTheme.success
        case .paused, .pomodoroBreak: TimelyTheme.warning
        }
    }

    private var modeSymbol: String {
        switch store.mode {
        case .idle: "circle"
        case .running: "record.circle"
        case .paused: "pause.circle"
        case .pomodoroWork: "timer"
        case .pomodoroBreak: "cup.and.saucer"
        }
    }

    private var activeAssignment: String {
        guard let span = store.activeSpan else { return "No client, project, or ticket selected" }
        let parts = [span.client, span.project, span.ticket].filter { !$0.isEmpty }
        return parts.isEmpty ? "No client, project, or ticket selected" : parts.joined(separator: " / ")
    }
}

struct TodayStatusStrip: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        HStack(spacing: 0) {
            CompactFact(label: "Tracked", value: store.reviewedDuration.timelyClock, systemImage: "clock")
            Divider().frame(height: 34)
            CompactFact(label: "Billable", value: store.billableDuration.timelyClock, systemImage: "dollarsign.circle", tint: TimelyTheme.success)
            Divider().frame(height: 34)
            CompactFact(label: "Evidence", value: "\(store.screenshots.count)", systemImage: "camera", detail: evidenceDetail)
            Divider().frame(height: 34)
            CompactFact(label: "AI", value: store.settings.vision.analysisEnabled ? "On" : "Off", systemImage: "eye", detail: "\(store.visionAnalyses.count) reviews", tint: store.settings.vision.analysisEnabled ? TimelyTheme.accent : TimelyTheme.secondaryText)
        }
        .timelyCard(padding: 0)
    }

    private var evidenceDetail: String {
        store.settings.screenshotCaptureEnabled ? "\(Int(store.settings.screenshotIntervalMinutes))m" : "manual"
    }
}

struct CompactFact: View {
    let label: String
    let value: String
    let systemImage: String
    var detail: String? = nil
    var tint: Color = TimelyTheme.accent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(TimelyTheme.secondaryText)
                HStack(spacing: 6) {
                    Text(value)
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(TimelyTheme.secondaryText)
                    }
                }
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TodayDetailTabs: View {
    @ObservedObject var store: TimelyStore
    @Binding var selectedTab: TodayDetailTab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Today detail", selection: $selectedTab) {
                ForEach(TodayDetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)

            switch selectedTab {
            case .activity:
                RecentSpansCard(store: store)
            case .evidence:
                EvidenceSummaryCard(store: store)
            case .ai:
                InsightCard(store: store)
            }
        }
    }
}

struct WorkScreen: View {
    @ObservedObject var store: TimelyStore
    @State private var selectedTab: WorkTab = .capture

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Work",
                    title: "Capture and review",
                    subtitle: "Start focused work, backfill missed time, and inspect the timeline without changing sections."
                ) {
                    StatusIndicator(store: store)
                }

                Picker("Work view", selection: $selectedTab) {
                    ForEach(WorkTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)

                switch selectedTab {
                case .capture:
                    CaptureTabContent(store: store)
                case .manual:
                    ManualEntryTabContent(store: store)
                case .timeline:
                    TimelineTabContent(store: store)
                }
            }
            .frame(maxWidth: 1180, alignment: .topLeading)
        }
    }
}

struct CaptureTabContent: View {
    @ObservedObject var store: TimelyStore
    @State private var mode: CapturePanelMode = .live

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Capture mode", selection: $mode) {
                ForEach(CapturePanelMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            switch mode {
            case .live:
                TaskControlCard(store: store)
            case .pomodoro:
                PomodoroCard(store: store)
            }
            CapturePolicyCard(store: store)
            RecentSpansCard(store: store)
        }
    }
}

struct ClientsScreen: View {
    @ObservedObject var store: TimelyStore
    @State private var selectedTab: DirectoryTab = .clients

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Directory",
                    title: "Clients and work",
                    subtitle: "Keep reusable clients, projects, and tickets available for time spans."
                ) {
                    TimelyStatusPill(title: "\(store.clients.count) clients", systemImage: "person.2", tint: TimelyTheme.accent)
                }

                Picker("Directory view", selection: $selectedTab) {
                    ForEach(DirectoryTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)

                switch selectedTab {
                case .clients:
                    ClientDirectoryCard(store: store)
                case .projects:
                    ProjectDirectoryCard(store: store)
                case .tickets:
                    TicketDirectoryCard(store: store)
                }
            }
            .frame(maxWidth: 960, alignment: .topLeading)
        }
    }
}

struct ClientDirectoryCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Clients", systemImage: "person.2")
                .font(.headline)
            HStack(spacing: 10) {
                TextField("Client name", text: $store.draftClientName)
                    .textFieldStyle(.roundedBorder)
                Button("Add", systemImage: "plus") { store.addClient() }
                    .buttonStyle(TimelyPrimaryButtonStyle())
                    .disabled(store.draftClientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.clients.isEmpty {
                EmptyStateView(message: "No clients yet. Add one here or start a span with a client name.")
            } else {
                ForEach(store.clients) { client in
                    DirectoryRow(
                        title: client.name,
                        subtitle: "\(store.projects.filter { $0.clientName.localizedCaseInsensitiveCompare(client.name) == .orderedSame }.count) projects / \(store.tickets.filter { $0.clientName.localizedCaseInsensitiveCompare(client.name) == .orderedSame }.count) tickets",
                        systemImage: "person.crop.square"
                    )
                    if client.id != store.clients.last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }
}

struct ProjectDirectoryCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Projects", systemImage: "folder")
                .font(.headline)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    TextField("Client", text: $store.draftProjectClient)
                    TextField("Project name", text: $store.draftProjectName)
                    Button("Add", systemImage: "plus") { store.addProject() }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                        .disabled(store.draftProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)

            if store.projects.isEmpty {
                EmptyStateView(message: "No projects yet.")
            } else {
                ForEach(store.projects) { project in
                    DirectoryRow(
                        title: project.name,
                        subtitle: project.clientName.isEmpty ? "No client" : project.clientName,
                        systemImage: "folder"
                    )
                    if project.id != store.projects.last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }
}

struct TicketDirectoryCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tickets", systemImage: "ticket")
                .font(.headline)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    TextField("Client", text: $store.draftTicketClient)
                    TextField("Project", text: $store.draftTicketProject)
                    TextField("Ticket name", text: $store.draftTicketName)
                    Button("Add", systemImage: "plus") { store.addTicket() }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                        .disabled(store.draftTicketName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)

            if store.tickets.isEmpty {
                EmptyStateView(message: "No tickets yet.")
            } else {
                ForEach(store.tickets) { ticket in
                    DirectoryRow(
                        title: ticket.name,
                        subtitle: [ticket.clientName, ticket.projectName].filter { !$0.isEmpty }.joined(separator: " / "),
                        systemImage: "ticket"
                    )
                    if ticket.id != store.tickets.last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }
}

struct DirectoryRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TimelyTheme.accent)
                .frame(width: 30, height: 30)
                .background(TimelyTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle.isEmpty ? "No assignment" : subtitle)
                    .font(.caption)
                    .foregroundStyle(TimelyTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ManualEntryTabContent: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ManualSpanCard(store: store)
            RecentSpansCard(store: store)
        }
    }
}

struct TimelineTabContent: View {
    @ObservedObject var store: TimelyStore
    @State private var evidenceSpan: TrackedTimeSpan?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.spans.isEmpty {
                EmptyStateView(message: "No captured intervals yet. Start a live span, Pomodoro, or add manual time.")
            } else {
                Table(store.spans) {
                    TableColumn("Work") { span in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(span.title)
                                .font(.body.weight(.medium))
                            Text(spanAssignment(span))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                        }
                    }
                    TableColumn("Start") { span in Text(span.start.formatted(date: .abbreviated, time: .shortened)) }
                    TableColumn("End") { span in Text(span.end?.formatted(date: .abbreviated, time: .shortened) ?? "Open") }
                    TableColumn("Duration") { span in Text(span.duration.timelyClock).monospacedDigit() }
                    TableColumn("Source") { span in Text(span.source.label) }
                    TableColumn("Evidence") { span in
                        let screenshots = screenshotsForSpan(span)
                        Button {
                            evidenceSpan = span
                        } label: {
                            Label("\(screenshots.count)", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(screenshots.isEmpty)
                    }
                    TableColumn("Billable") { span in
                        Label(span.isBillable ? "Billable" : "Non-billable", systemImage: span.isBillable ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(span.isBillable ? TimelyTheme.success : TimelyTheme.secondaryText)
                    }
                    TableColumn("Actions") { span in
                        Button("Delete", role: .destructive) { store.deleteSpan(span) }
                    }
                }
                .timelyCard(padding: 0)
                .frame(minHeight: 420)
            }
        }
        .sheet(item: $evidenceSpan) { span in
            SpanEvidenceSheet(store: store, span: span)
        }
    }

    private func screenshotsForSpan(_ span: TrackedTimeSpan) -> [ScreenshotRecord] {
        store.screenshots.filter { $0.spanID == span.id }
    }

    private func spanAssignment(_ span: TrackedTimeSpan) -> String {
        let parts = [span.client, span.project, span.ticket].filter { !$0.isEmpty }
        return parts.isEmpty ? "No client, project, or ticket" : parts.joined(separator: " / ")
    }
}

struct SpanEvidenceSheet: View {
    @ObservedObject var store: TimelyStore
    let span: TrackedTimeSpan

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelyPageHeader(
                eyebrow: "Evidence",
                title: span.title,
                subtitle: span.project.isEmpty ? "Screenshot evidence attached to this span." : span.project
            ) {
                Button("Open folder", systemImage: "folder") { store.openScreenshotsFolder() }
                    .buttonStyle(TimelySecondaryButtonStyle())
            }

            let screenshots = screenshotsForSpan()
            if screenshots.isEmpty {
                EmptyStateView(message: "No screenshot evidence is attached to this span.")
            } else {
                List(screenshots) { screenshot in
                    EvidenceRow(
                        screenshot: screenshot,
                        analysis: store.visionAnalyses.first { $0.screenshotID == screenshot.id },
                        screenshotURL: store.screenshotsURL.appendingPathComponent(screenshot.fileName)
                    )
                }
                .listStyle(.plain)
                .timelyCard(padding: 0)
            }
        }
        .padding(24)
        .frame(width: 760, height: 560)
    }

    private func screenshotsForSpan() -> [ScreenshotRecord] {
        store.screenshots.filter { $0.spanID == span.id }
    }
}

struct CaptureScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Live Capture",
                    title: "Start, pause, resume",
                    subtitle: "Name the work before capture so later screenshots and AI analysis have context."
                ) {
                    StatusIndicator(store: store)
                }
                TaskControlCard(store: store)
                CapturePolicyCard(store: store)
                RecentSpansCard(store: store)
            }
            .frame(maxWidth: 1040, alignment: .topLeading)
        }
    }
}

struct ManualEntryScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Corrections",
                    title: "Manual time span",
                    subtitle: "Backfill finished work without starting a live capture session."
                ) {
                    Button("Add span", systemImage: "plus") { store.addManualSpan() }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                        .disabled(store.manualTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ManualSpanCard(store: store)
                RecentSpansCard(store: store)
            }
            .frame(maxWidth: 1040, alignment: .topLeading)
        }
    }
}

struct TimelineScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            TimelyPageHeader(
                eyebrow: "Review",
                title: "Timeline",
                subtitle: "Inspect live, manual, and Pomodoro spans in one correction table."
            ) {
                StatusIndicator(store: store)
            }

            if store.spans.isEmpty {
                EmptyStateView(message: "No captured intervals yet. Start a live span, Pomodoro, or add manual time.")
            } else {
                Table(store.spans) {
                    TableColumn("Work") { span in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(span.title)
                                .font(.body.weight(.medium))
                            Text(spanAssignment(span))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                        }
                    }
                    TableColumn("Start") { span in Text(span.start.formatted(date: .abbreviated, time: .shortened)) }
                    TableColumn("End") { span in Text(span.end?.formatted(date: .abbreviated, time: .shortened) ?? "Open") }
                    TableColumn("Duration") { span in Text(span.duration.timelyClock).monospacedDigit() }
                    TableColumn("Source") { span in Text(span.source.label) }
                    TableColumn("Billable") { span in
                        Label(span.isBillable ? "Billable" : "Non-billable", systemImage: span.isBillable ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(span.isBillable ? TimelyTheme.success : TimelyTheme.secondaryText)
                    }
                    TableColumn("Actions") { span in
                        Button("Delete", role: .destructive) { store.deleteSpan(span) }
                    }
                }
                .timelyCard(padding: 0)
            }
        }
    }

    private func spanAssignment(_ span: TrackedTimeSpan) -> String {
        let parts = [span.client, span.project, span.ticket].filter { !$0.isEmpty }
        return parts.isEmpty ? "No client, project, or ticket" : parts.joined(separator: " / ")
    }
}

struct EvidenceScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            TimelyPageHeader(
                eyebrow: "Evidence",
                title: "Screenshots and AI observations",
                subtitle: "Capture visual evidence on demand or on a periodic cadence while a span is active."
            ) {
                HStack {
                    Button("Capture now", systemImage: "camera") { store.captureScreenshotNow() }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                    Button("Open folder", systemImage: "folder") { store.openScreenshotsFolder() }
                        .buttonStyle(TimelySecondaryButtonStyle())
                }
            }

            if store.screenshots.isEmpty {
                EmptyStateView(message: "No screenshot evidence has been captured.")
            } else {
                List(store.screenshots) { screenshot in
                    EvidenceRow(
                        screenshot: screenshot,
                        analysis: store.visionAnalyses.first { $0.screenshotID == screenshot.id },
                        screenshotURL: store.screenshotsURL.appendingPathComponent(screenshot.fileName)
                    )
                }
                .listStyle(.plain)
                .timelyCard(padding: 0)
            }
        }
    }
}

struct VisionLLMScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "AI Configuration",
                    title: "Vision LLM",
                    subtitle: "Analyze periodic screenshots to extract status updates and detect project switches."
                ) {
                    HStack {
                        if store.isAnalyzingVisionScreenshot {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Button("Analyze latest", systemImage: "sparkle.magnifyingglass") {
                            Task { await store.analyzeLatestScreenshot() }
                        }
                        .buttonStyle(TimelyPrimaryButtonStyle())
                        .disabled(store.screenshots.isEmpty || store.isAnalyzingVisionScreenshot)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    VisionConfigCard(store: store)
                    VisionResultCard(store: store)
                }
            }
            .frame(maxWidth: 1180, alignment: .topLeading)
        }
    }
}

struct PomodoroScreen: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TimelyPageHeader(
                    eyebrow: "Focus",
                    title: "Pomodoro",
                    subtitle: "Run a timed focus span using the current task name from Capture."
                ) {
                    StatusIndicator(store: store)
                }
                PomodoroCard(store: store)
                TaskControlCard(store: store)
            }
            .frame(maxWidth: 1040, alignment: .topLeading)
        }
    }
}

struct StatusIndicator: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TimelyStatusPill(title: store.mode.label, systemImage: modeSymbol, tint: modeTint)
            if let active = store.activeSpan {
                Text(active.duration.timelyClock)
                    .font(.system(size: 24, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text("No active span")
                    .font(.caption)
                    .foregroundStyle(TimelyTheme.secondaryText)
            }
        }
    }

    private var modeTint: Color {
        switch store.mode {
        case .idle: TimelyTheme.secondaryText
        case .running, .pomodoroWork: TimelyTheme.success
        case .paused, .pomodoroBreak: TimelyTheme.warning
        }
    }

    private var modeSymbol: String {
        switch store.mode {
        case .idle: "circle"
        case .running: "record.circle"
        case .paused: "pause.circle"
        case .pomodoroWork: "timer"
        case .pomodoroBreak: "cup.and.saucer"
        }
    }
}

struct TaskControlCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Current span", systemImage: "record.circle")
                    .font(.headline)
                Spacer()
                if store.settings.screenshotCaptureEnabled {
                    TimelyStatusPill(title: "\(Int(store.settings.screenshotIntervalMinutes))m screenshots", systemImage: "repeat", tint: TimelyTheme.accent)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Task name")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TimelyTheme.secondaryText)
                        TextField("e.g. Implement Timely vision analysis", text: $store.currentTask)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Client")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TimelyTheme.secondaryText)
                        TextField("e.g. Noizu", text: $store.currentClient)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                GridRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TimelyTheme.secondaryText)
                        TextField("e.g. timely.noizu.com", text: $store.currentProject)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ticket")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TimelyTheme.secondaryText)
                        TextField("e.g. TIM-124", text: $store.currentTicket)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Start", systemImage: "play.fill") { store.startSpan() }
                    .buttonStyle(TimelyPrimaryButtonStyle())
                Button(store.mode == .paused ? "Resume" : "Pause", systemImage: store.mode == .paused ? "play.fill" : "pause.fill") {
                    store.mode == .paused ? store.resume() : store.pause()
                }
                .buttonStyle(TimelySecondaryButtonStyle())
                .disabled(store.activeSpanID == nil)
                Button("Stop", systemImage: "stop.fill") { store.stopActiveSpan() }
                    .buttonStyle(TimelySecondaryButtonStyle())
                    .disabled(store.activeSpanID == nil)
                Button {
                    store.captureScreenshotNow()
                } label: {
                    Image(systemName: "camera")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(TimelyIconButtonStyle())
                .help("Capture screenshot now")
            }

            if let active = store.activeSpan {
                Divider()
                HStack {
                    LabeledContent("Started", value: active.start.formatted(date: .omitted, time: .shortened))
                    LabeledContent("Elapsed", value: active.duration.timelyClock)
                    LabeledContent("Source", value: active.source.label)
                }
                .font(.callout)
            }
        }
        .timelyCard()
    }
}

struct ManualSpanCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Recovered work", systemImage: "square.and.pencil")
                .font(.headline)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    TextField("Title", text: $store.manualTitle)
                    TextField("Client", text: $store.manualClient)
                }
                GridRow {
                    TextField("Project", text: $store.manualProject)
                    TextField("Ticket", text: $store.manualTicket)
                }
                GridRow {
                    DatePicker("Start", selection: $store.manualStart)
                    DatePicker("End", selection: $store.manualEnd)
                }
            }
            .textFieldStyle(.roundedBorder)

            Toggle("Billable", isOn: $store.manualBillable)

            TextField("Notes", text: $store.manualNotes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            Button("Add manual time span", systemImage: "plus") { store.addManualSpan() }
                .buttonStyle(TimelyPrimaryButtonStyle())
                .disabled(store.manualTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .timelyCard()
    }
}

struct PomodoroCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(store.mode == .pomodoroBreak ? "Break timer" : "Focus timer", systemImage: "timer")
                    .font(.headline)
                Spacer()
                Text(store.pomodoroRemaining > 0 ? store.pomodoroRemaining.timelyClock : "\(Int(store.settings.pomodoroWorkMinutes)):00")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                Button("Start Pomodoro", systemImage: "play.fill") { store.startPomodoro() }
                    .buttonStyle(TimelyPrimaryButtonStyle())
                Button("Finish Focus", systemImage: "checkmark") { store.completePomodoroNow() }
                    .buttonStyle(TimelySecondaryButtonStyle())
                    .disabled(store.mode != .pomodoroWork)
                Button("End Break", systemImage: "stop.fill") { store.finishBreak() }
                    .buttonStyle(TimelySecondaryButtonStyle())
                    .disabled(store.mode != .pomodoroBreak)
            }

            Divider()
            HStack {
                LabeledContent("Focus", value: "\(Int(store.settings.pomodoroWorkMinutes)) minutes")
                LabeledContent("Break", value: "\(Int(store.settings.pomodoroBreakMinutes)) minutes")
            }
        }
        .timelyCard()
    }
}

struct CapturePolicyCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Capture policy", systemImage: "shield")
                .font(.headline)
            Toggle("Enable periodic screenshots", isOn: $store.settings.screenshotCaptureEnabled)
                .onChange(of: store.settings.screenshotCaptureEnabled) { store.settingsChanged() }
            Stepper("Screenshot interval: \(Int(store.settings.screenshotIntervalMinutes)) minutes", value: $store.settings.screenshotIntervalMinutes, in: 1...60, step: 1)
                .onChange(of: store.settings.screenshotIntervalMinutes) { store.settingsChanged() }
            Toggle("Store screenshots locally only", isOn: $store.settings.localOnlyScreenshots)
                .onChange(of: store.settings.localOnlyScreenshots) { store.settingsChanged() }
            Button("Open screenshots folder", systemImage: "folder") { store.openScreenshotsFolder() }
                .buttonStyle(TimelySecondaryButtonStyle())
        }
        .timelyCard()
    }
}

struct InsightCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Latest AI status", systemImage: "eye")
                    .font(.headline)
                Spacer()
                TimelyStatusPill(
                    title: store.settings.vision.analysisEnabled ? "Enabled" : "Disabled",
                    systemImage: store.settings.vision.analysisEnabled ? "checkmark.circle" : "circle",
                    tint: store.settings.vision.analysisEnabled ? TimelyTheme.success : TimelyTheme.secondaryText
                )
            }

            if let analysis = store.visionAnalyses.first {
                Text(analysis.statusUpdate)
                    .font(.body)
                HStack {
                    Text(analysis.inferredProject.isEmpty ? "No project inferred" : analysis.inferredProject)
                    Spacer()
                    Text("\(Int(analysis.confidence * 100))% confidence")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(TimelyTheme.secondaryText)
                if analysis.projectSwitchDetected {
                    TimelyStatusPill(title: "Project switch", systemImage: "arrow.triangle.branch", tint: TimelyTheme.warning)
                }
            } else {
                EmptyStateView(message: "No vision analysis yet. Enable Vision LLM and capture a screenshot.")
            }
        }
        .timelyCard()
    }
}

struct RecentSpansCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent spans", systemImage: "list.bullet.rectangle")
                .font(.headline)
            if store.spans.isEmpty {
                EmptyStateView(message: "No time spans yet.")
            } else {
                ForEach(Array(store.spans.prefix(5))) { span in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(span.title)
                                .font(.body.weight(.medium))
                                .lineLimit(1)
                            Text(spanAssignment(span))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                        }
                        Spacer()
                        Text(span.duration.timelyClock)
                            .font(.callout.monospacedDigit())
                    }
                    if span.id != store.spans.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }

    private func spanAssignment(_ span: TrackedTimeSpan) -> String {
        let parts = [span.client, span.project, span.ticket].filter { !$0.isEmpty }
        return parts.isEmpty ? span.source.label : parts.joined(separator: " / ")
    }
}

struct EvidenceSummaryCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evidence", systemImage: "photo.on.rectangle")
                .font(.headline)
            if let screenshot = store.screenshots.first {
                EvidenceRow(
                    screenshot: screenshot,
                    analysis: store.visionAnalyses.first { $0.screenshotID == screenshot.id },
                    screenshotURL: store.screenshotsURL.appendingPathComponent(screenshot.fileName)
                )
            } else {
                EmptyStateView(message: "No screenshots yet. Capture one from the toolbar or Capture screen.")
            }
        }
        .timelyCard()
    }
}

struct VisionConfigCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Connection", systemImage: "network")
                .font(.headline)

            Toggle("Analyze periodic screenshots", isOn: $store.settings.vision.analysisEnabled)
                .onChange(of: store.settings.vision.analysisEnabled) { store.settingsChanged() }

            Toggle("Notify on likely project switch", isOn: $store.settings.vision.notifyOnProjectSwitch)
                .onChange(of: store.settings.vision.notifyOnProjectSwitch) {
                    store.settingsChanged()
                    Task { await store.requestNotificationPermission() }
                }

            Toggle("Censor screenshots with private content", isOn: $store.settings.vision.privacyRedactionEnabled)
                .onChange(of: store.settings.vision.privacyRedactionEnabled) { store.settingsChanged() }

            Toggle("Notify when a screenshot is censored", isOn: $store.settings.vision.notifyOnCensoredScreenshot)
                .onChange(of: store.settings.vision.notifyOnCensoredScreenshot) {
                    store.settingsChanged()
                    Task { await store.requestNotificationPermission() }
                }

            Picker("Provider", selection: $store.settings.vision.provider) {
                ForEach(VisionLLMSettings.providers, id: \.self) { provider in
                    Text(provider).tag(provider)
                }
            }
            .onChange(of: store.settings.vision.provider) {
                let provider = store.settings.vision.provider
                store.settings.vision.model = VisionLLMSettings.defaultModels[provider] ?? store.settings.vision.model
                store.settings.vision.baseURL = VisionLLMSettings.defaultBaseURLs[provider] ?? store.settings.vision.baseURL
                store.settings.vision.apiKey = VisionLLMSettings.defaultAPIKeys[provider] ?? store.settings.vision.apiKey
                store.settingsChanged()
            }

            TextField("Model", text: $store.settings.vision.model)
                .textFieldStyle(.roundedBorder)
                .onChange(of: store.settings.vision.model) { store.settingsChanged() }

            TextField("Base URL", text: $store.settings.vision.baseURL)
                .textFieldStyle(.roundedBorder)
                .onChange(of: store.settings.vision.baseURL) { store.settingsChanged() }

            TextField("API key or env: NAME", text: $store.settings.vision.apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onChange(of: store.settings.vision.apiKey) { store.settingsChanged() }

            Stepper("Switch confidence: \(Int(store.settings.vision.confidenceThreshold * 100))%", value: $store.settings.vision.confidenceThreshold, in: 0.30...0.95, step: 0.01)
                .onChange(of: store.settings.vision.confidenceThreshold) { store.settingsChanged() }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TimelyTheme.secondaryText)
                TextField("Prompt", text: $store.settings.vision.prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(8...12)
                    .onChange(of: store.settings.vision.prompt) { store.settingsChanged() }
            }
        }
        .timelyCard()
    }
}

struct VisionResultCard: View {
    @ObservedObject var store: TimelyStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Analysis history", systemImage: "sparkles")
                .font(.headline)
            if store.visionAnalyses.isEmpty {
                EmptyStateView(message: "No analyses yet. Capture a screenshot, then run Analyze latest or enable automatic analysis.")
            } else {
                ForEach(Array(store.visionAnalyses.prefix(8))) { analysis in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(analysis.analyzedAt.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                            Spacer()
                            TimelyStatusPill(
                                title: analysis.errorMessage == nil ? "\(Int(analysis.confidence * 100))%" : "Error",
                                systemImage: analysis.errorMessage == nil ? "gauge.with.dots.needle.33percent" : "exclamationmark.triangle",
                                tint: analysis.errorMessage == nil ? TimelyTheme.success : TimelyTheme.danger
                            )
                        }
                        Text(analysis.errorMessage ?? analysis.statusUpdate)
                            .font(.body)
                        if !analysis.inferredProject.isEmpty || !analysis.inferredTask.isEmpty {
                            Text([analysis.inferredProject, analysis.inferredTask].filter { !$0.isEmpty }.joined(separator: " / "))
                                .font(.caption)
                                .foregroundStyle(TimelyTheme.secondaryText)
                        }
                        if analysis.projectSwitchDetected {
                            TimelyStatusPill(title: "Likely project switch", systemImage: "arrow.triangle.branch", tint: TimelyTheme.warning)
                        }
                    }
                    .padding(.vertical, 6)
                    if analysis.id != store.visionAnalyses.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
        .timelyCard()
    }
}

struct EvidenceRow: View {
    let screenshot: ScreenshotRecord
    let analysis: VisionAnalysisRecord?
    let screenshotURL: URL

    var body: some View {
        HStack(spacing: 12) {
            ScreenshotThumbnail(url: screenshotURL)
            VStack(alignment: .leading, spacing: 5) {
                Text(screenshot.fileName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(screenshot.capturedAt.formatted(date: .abbreviated, time: .standard)) / \(screenshot.activeAppName)")
                    .font(.caption)
                    .foregroundStyle(TimelyTheme.secondaryText)
                if let analysis {
                    Text(analysis.errorMessage ?? analysis.statusUpdate)
                        .font(.caption)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if !analysis.inferredProject.isEmpty {
                            TimelyStatusPill(title: analysis.inferredProject, systemImage: "folder", tint: TimelyTheme.accent)
                        }
                        if analysis.projectSwitchDetected {
                            TimelyStatusPill(title: "Switch", systemImage: "arrow.triangle.branch", tint: TimelyTheme.warning)
                        }
                    }
                }
            }
            Spacer()
            Button("Reveal", systemImage: "magnifyingglass") {
                NSWorkspace.shared.activateFileViewerSelecting([screenshotURL])
            }
            .buttonStyle(TimelySecondaryButtonStyle())
        }
        .padding(10)
    }
}

struct ScreenshotThumbnail: View {
    let url: URL

    var body: some View {
        Group {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(TimelyTheme.secondaryText)
            }
        }
        .frame(width: 92, height: 58)
        .background(TimelyTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(TimelyTheme.border))
    }
}

struct UseCasesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Primary workflows", systemImage: "checklist")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                UseCaseTile(title: "Start and pause", detail: "Use Capture to name a task, start a span, pause, resume, and stop.")
                UseCaseTile(title: "Backfill time", detail: "Use Manual Entry for completed work with exact start and end times.")
                UseCaseTile(title: "Review evidence", detail: "Open Timeline and click the evidence count on a span.")
                UseCaseTile(title: "Run Pomodoro", detail: "Use Capture to start a timed focus span with a break.")
                UseCaseTile(title: "Detect switches", detail: "Use Settings to configure Vision LLM project-switch detection.")
                UseCaseTile(title: "Tune privacy", detail: "Use Settings for retention, local storage, and screenshot censoring.")
            }
        }
        .timelyCard()
    }
}

struct UseCaseTile: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(TimelyTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(TimelyTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: TimelyTheme.radius))
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(TimelyTheme.danger)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TimelyTheme.danger.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: TimelyTheme.radius))
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(TimelyTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(TimelyTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: TimelyTheme.radius))
    }
}
