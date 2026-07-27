import SwiftUI
import TheRobotPlansCore

@main
struct TheRobotPlansApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(snapshot: MobileSeedData.snapshot)
        }
    }
}

struct RootView: View {
    let snapshot: MobileSnapshot

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedLane: LaneKind? = .inbox
    @State private var selectedItem: WorkItem?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .tint(.teal)
    }

    private var iPhoneLayout: some View {
        TabView {
            NavigationStack {
                TodayView(snapshot: snapshot)
                    .navigationTitle("Today")
            }
            .tabItem { Label("Today", systemImage: "sun.max") }

            NavigationStack {
                CaptureView(queuedCount: snapshot.queuedCaptureCount)
                    .navigationTitle("Capture")
            }
            .tabItem { Label("Capture", systemImage: "plus.circle") }

            NavigationStack {
                LaneListView(snapshot: snapshot, selectedLane: $selectedLane)
                    .navigationTitle("Lanes")
            }
            .tabItem { Label("Lanes", systemImage: "square.grid.2x2") }

            NavigationStack {
                AgentsView(agents: snapshot.agents)
                    .navigationTitle("Agents")
            }
            .tabItem { Label("Agents", systemImage: "person.2.wave.2") }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            LaneListView(snapshot: snapshot, selectedLane: $selectedLane)
                .navigationTitle("Plans")
        } content: {
            if let selectedLane {
                ItemListView(
                    title: selectedLane.title,
                    items: snapshot.items(in: selectedLane),
                    selectedItem: $selectedItem
                )
                .navigationTitle(selectedLane.title)
            } else {
                ContentUnavailableView("Choose a lane", systemImage: "square.grid.2x2")
            }
        } detail: {
            if let selectedItem {
                ItemDetailView(item: selectedItem)
            } else {
                DashboardView(snapshot: snapshot)
            }
        }
    }
}

struct DashboardView: View {
    let snapshot: MobileSnapshot

    var body: some View {
        List {
            Section {
                SummaryCards(snapshot: snapshot)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("Urgent") {
                ForEach(snapshot.todayItems.filter { $0.priority == .urgent }) { item in
                    ItemRow(item: item)
                }
            }

            Section("Agents") {
                ForEach(snapshot.agents) { agent in
                    AgentRow(agent: agent)
                }
            }
        }
        .navigationTitle("Operations")
    }
}

struct TodayView: View {
    let snapshot: MobileSnapshot

    var body: some View {
        List {
            Section {
                SummaryCards(snapshot: snapshot)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("Next actions") {
                ForEach(snapshot.todayItems) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemRow(item: item)
                    }
                }
            }
        }
    }
}

struct CaptureView: View {
    let queuedCount: Int

    @State private var draft = CaptureDraft(tags: ["mobile"])
    @State private var submittedDrafts: [CaptureDraft] = []

    var body: some View {
        Form {
            Section("Quick capture") {
                TextEditor(text: $draft.text)
                    .frame(minHeight: 140)
                    .accessibilityLabel("Capture text")

                Toggle("Queue offline", isOn: $draft.queuedOffline)

                Button {
                    submittedDrafts.insert(draft, at: 0)
                    draft = CaptureDraft(tags: ["mobile"], queuedOffline: draft.queuedOffline)
                } label: {
                    Label("Capture", systemImage: "tray.and.arrow.down")
                }
                .disabled(!draft.canSubmit)
            }

            Section("Status") {
                LabeledContent("Queued before launch", value: "\(queuedCount)")
                LabeledContent("Captured this session", value: "\(submittedDrafts.count)")
                Label("Share-sheet and photo intake are API contract follow-ups.", systemImage: "square.and.arrow.down")
            }

            if !submittedDrafts.isEmpty {
                Section("Session queue") {
                    ForEach(submittedDrafts.indices, id: \.self) { index in
                        Text(submittedDrafts[index].text)
                            .lineLimit(3)
                    }
                }
            }
        }
    }
}

struct LaneListView: View {
    let snapshot: MobileSnapshot
    @Binding var selectedLane: LaneKind?

    var body: some View {
        List(selection: $selectedLane) {
            Section("Work lanes") {
                ForEach(snapshot.laneSummaries) { summary in
                    NavigationLink(value: summary.id) {
                        LaneSummaryRow(summary: summary)
                    }
                }
            }
        }
    }
}

struct ItemListView: View {
    let title: String
    let items: [WorkItem]
    @Binding var selectedItem: WorkItem?

    var body: some View {
        List(items, selection: $selectedItem) { item in
            ItemRow(item: item)
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No active \(title.lowercased()) items", systemImage: "checkmark.circle")
            }
        }
    }
}

struct AgentsView: View {
    let agents: [AgentStatus]

    var body: some View {
        List {
            ForEach(agents) { agent in
                AgentRow(agent: agent)
            }
        }
    }
}

struct SummaryCards: View {
    let snapshot: MobileSnapshot

    private var blockedCount: Int {
        snapshot.todayItems.filter { $0.state == .blocked }.count
    }

    private var urgentCount: Int {
        snapshot.todayItems.filter { $0.priority == .urgent }.count
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricCard(label: "Open", value: "\(snapshot.todayItems.count)", systemImage: "list.bullet.rectangle")
            MetricCard(label: "Urgent", value: "\(urgentCount)", systemImage: "exclamationmark.triangle")
            MetricCard(label: "Blocked", value: "\(blockedCount)", systemImage: "hand.raised")
            MetricCard(label: "Queued", value: "\(snapshot.queuedCaptureCount)", systemImage: "tray.full")
        }
        .padding(.vertical, 6)
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct LaneSummaryRow: View {
    let summary: LaneSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: summary.id.systemImage)
                .frame(width: 28, height: 28)
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.title)
                    .font(.headline)
                Text("\(summary.total) open, \(summary.blocked) blocked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if summary.urgent > 0 {
                Text("\(summary.urgent)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.16), in: Capsule())
                    .foregroundStyle(.red)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ItemRow: View {
    let item: WorkItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(.headline)
                Spacer(minLength: 12)
                PriorityBadge(priority: item.priority)
            }

            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(item.lane.title, systemImage: item.lane.systemImage)
                if let dueLabel = item.dueLabel {
                    Label(dueLabel, systemImage: "calendar")
                }
                Spacer()
                Text(item.state.title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct ItemDetailView: View {
    let item: WorkItem

    var body: some View {
        Form {
            Section("Item") {
                LabeledContent("Title", value: item.title)
                LabeledContent("Lane", value: item.lane.title)
                LabeledContent("State", value: item.state.title)
                LabeledContent("Priority", value: item.priority.title)
                if let dueLabel = item.dueLabel {
                    LabeledContent("Due", value: dueLabel)
                }
                if let owner = item.owner {
                    LabeledContent("Owner", value: owner)
                }
            }

            Section("Context") {
                Text(item.summary)
            }

            Section("Actions") {
                Button {} label: {
                    Label("Open web workspace", systemImage: "safari")
                }
                Button {} label: {
                    Label("Assign agent", systemImage: "person.badge.plus")
                }
                Button {} label: {
                    Label("Add checklist", systemImage: "checklist")
                }
            }
        }
        .navigationTitle(item.title)
    }
}

struct AgentRow: View {
    let agent: AgentStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(agent.name)
                    .font(.headline)
                Spacer()
                Text(agent.status)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.teal.opacity(0.14), in: Capsule())
            }

            Text(agent.role)
                .font(.subheadline.weight(.medium))

            Text(agent.currentTask)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct PriorityBadge: View {
    let priority: WorkPriority

    var body: some View {
        Text(priority.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch priority {
        case .low: .secondary
        case .normal: .blue
        case .high: .orange
        case .urgent: .red
        }
    }
}

#Preview("iPhone") {
    RootView(snapshot: MobileSeedData.snapshot)
}

#Preview("iPad", traits: .landscapeLeft) {
    RootView(snapshot: MobileSeedData.snapshot)
}
