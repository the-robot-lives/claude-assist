import Foundation

public enum LaneKind: String, CaseIterable, Codable, Sendable {
    case personal
    case inbox
    case projects
    case pipelines
    case monitoring
    case wiki
    case goals
    case agents
    case prompts

    public var title: String {
        switch self {
        case .personal: "Personal"
        case .inbox: "Inbox"
        case .projects: "Projects"
        case .pipelines: "Pipelines"
        case .monitoring: "Monitoring"
        case .wiki: "Wiki"
        case .goals: "Goals"
        case .agents: "Agents"
        case .prompts: "Prompts"
        }
    }

    public var systemImage: String {
        switch self {
        case .personal: "checklist"
        case .inbox: "tray.and.arrow.down"
        case .projects: "rectangle.stack"
        case .pipelines: "point.3.connected.trianglepath.dotted"
        case .monitoring: "waveform.path.ecg"
        case .wiki: "books.vertical"
        case .goals: "target"
        case .agents: "person.2.wave.2"
        case .prompts: "quote.bubble"
        }
    }
}

public enum WorkPriority: String, CaseIterable, Codable, Sendable {
    case low
    case normal
    case high
    case urgent

    public var title: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }
}

public enum WorkState: String, CaseIterable, Codable, Sendable {
    case captured
    case planned
    case blocked
    case inProgress
    case needsReview
    case done

    public var title: String {
        switch self {
        case .captured: "Captured"
        case .planned: "Planned"
        case .blocked: "Blocked"
        case .inProgress: "In Progress"
        case .needsReview: "Review"
        case .done: "Done"
        }
    }
}

public struct WorkItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var lane: LaneKind
    public var state: WorkState
    public var priority: WorkPriority
    public var dueLabel: String?
    public var owner: String?
    public var summary: String

    public init(
        id: UUID = UUID(),
        title: String,
        lane: LaneKind,
        state: WorkState,
        priority: WorkPriority = .normal,
        dueLabel: String? = nil,
        owner: String? = nil,
        summary: String
    ) {
        self.id = id
        self.title = title
        self.lane = lane
        self.state = state
        self.priority = priority
        self.dueLabel = dueLabel
        self.owner = owner
        self.summary = summary
    }
}

public struct AgentStatus: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var role: String
    public var status: String
    public var currentTask: String

    public init(
        id: UUID = UUID(),
        name: String,
        role: String,
        status: String,
        currentTask: String
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.status = status
        self.currentTask = currentTask
    }
}

public struct CaptureDraft: Equatable, Codable, Sendable {
    public var text: String
    public var tags: [String]
    public var queuedOffline: Bool

    public init(text: String = "", tags: [String] = [], queuedOffline: Bool = false) {
        self.text = text
        self.tags = tags
        self.queuedOffline = queuedOffline
    }

    public var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public struct LaneSummary: Identifiable, Hashable, Sendable {
    public let id: LaneKind
    public var total: Int
    public var blocked: Int
    public var urgent: Int

    public var title: String { id.title }
}

public struct MobileSnapshot: Equatable, Sendable {
    public var items: [WorkItem]
    public var agents: [AgentStatus]
    public var queuedCaptureCount: Int

    public init(items: [WorkItem], agents: [AgentStatus], queuedCaptureCount: Int) {
        self.items = items
        self.agents = agents
        self.queuedCaptureCount = queuedCaptureCount
    }

    public var todayItems: [WorkItem] {
        items
            .filter { $0.state != .done }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return priorityRank(lhs.priority) > priorityRank(rhs.priority)
                }

                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    public func items(in lane: LaneKind) -> [WorkItem] {
        todayItems.filter { $0.lane == lane }
    }

    public var laneSummaries: [LaneSummary] {
        LaneKind.allCases.map { lane in
            let laneItems = items(in: lane)
            return LaneSummary(
                id: lane,
                total: laneItems.count,
                blocked: laneItems.filter { $0.state == .blocked }.count,
                urgent: laneItems.filter { $0.priority == .urgent }.count
            )
        }
    }
}

private func priorityRank(_ priority: WorkPriority) -> Int {
    switch priority {
    case .low: 0
    case .normal: 1
    case .high: 2
    case .urgent: 3
    }
}
