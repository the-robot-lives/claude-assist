import Foundation

public enum MobileSeedData {
    public static let snapshot = MobileSnapshot(
        items: [
            WorkItem(
                id: UUID(uuidString: "1EC65D1F-0F59-46B0-A886-1A8B7D6A1511")!,
                title: "Review today plan",
                lane: .personal,
                state: .planned,
                priority: .high,
                dueLabel: "Today",
                owner: "Keith",
                summary: "Pull personal items, project commitments, and agent blockers into a single morning review."
            ),
            WorkItem(
                id: UUID(uuidString: "F2516570-04D3-4A6D-9E6B-3E79A79C08E3")!,
                title: "Triage mobile capture queue",
                lane: .inbox,
                state: .captured,
                priority: .urgent,
                dueLabel: "Now",
                owner: "Inbox agent",
                summary: "Classify quick notes, screenshots, and share-sheet captures before they leak out of context."
            ),
            WorkItem(
                id: UUID(uuidString: "5647FEAA-01BB-48A6-8F3C-79604E0C84EA")!,
                title: "Publish project methodology presets",
                lane: .projects,
                state: .inProgress,
                priority: .high,
                dueLabel: "This week",
                owner: "PM agent",
                summary: "Expose Scrum, Kanban, Waterfall, GTD, and custom workflows as methodology views over shared items."
            ),
            WorkItem(
                id: UUID(uuidString: "CEB2297A-4E82-4D29-82AE-3BB36B21F7AA")!,
                title: "Investigate failed deploy",
                lane: .pipelines,
                state: .blocked,
                priority: .urgent,
                dueLabel: "Today",
                owner: "Deploy agent",
                summary: "Surface a failed pipeline as an actionable item with linked commit, environment, and rollback context."
            ),
            WorkItem(
                id: UUID(uuidString: "567AC935-7E03-4B7A-B865-76C6A76C410C")!,
                title: "Refresh OKR check-in",
                lane: .goals,
                state: .needsReview,
                priority: .normal,
                dueLabel: "Friday",
                owner: "Keith",
                summary: "Draft a weekly OKR update from completed items, missed habits, incidents, and agent activity."
            )
        ],
        agents: [
            AgentStatus(
                id: UUID(uuidString: "8C8B2F7E-4065-41A4-B669-96E8B04DCFEA")!,
                name: "Maya",
                role: "Monitoring",
                status: "Watching",
                currentTask: "Correlating uptime signals with recent deploys."
            ),
            AgentStatus(
                id: UUID(uuidString: "12049798-693B-4061-B89E-16E964CB57F8")!,
                name: "Raj",
                role: "Inbox",
                status: "Queued",
                currentTask: "Waiting for mobile captures to sync."
            ),
            AgentStatus(
                id: UUID(uuidString: "249C7CB4-9DC2-4D4C-9812-B371C90A6901")!,
                name: "Lin",
                role: "Prompt archive",
                status: "Ready",
                currentTask: "Versioning agent role prompts."
            )
        ],
        queuedCaptureCount: 2
    )
}
