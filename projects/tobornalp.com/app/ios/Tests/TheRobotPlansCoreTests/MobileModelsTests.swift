import XCTest
@testable import TheRobotPlansCore

final class MobileModelsTests: XCTestCase {
    func testCaptureDraftRequiresNonWhitespaceText() {
        XCTAssertFalse(CaptureDraft(text: "   \n\t").canSubmit)
        XCTAssertTrue(CaptureDraft(text: "Buy batteries #home").canSubmit)
    }

    func testTodayItemsExcludeDoneAndSortUrgentFirst() {
        let done = WorkItem(
            title: "Already handled",
            lane: .personal,
            state: .done,
            priority: .urgent,
            summary: "Should not appear."
        )
        let normal = WorkItem(
            title: "Normal item",
            lane: .wiki,
            state: .planned,
            priority: .normal,
            summary: "Lower priority."
        )
        let urgent = WorkItem(
            title: "Urgent item",
            lane: .pipelines,
            state: .blocked,
            priority: .urgent,
            summary: "Needs attention."
        )

        let snapshot = MobileSnapshot(items: [normal, done, urgent], agents: [], queuedCaptureCount: 0)

        XCTAssertEqual(snapshot.todayItems.map(\.title), ["Urgent item", "Normal item"])
    }

    func testLaneSummariesCountOpenBlockedAndUrgentItems() throws {
        let snapshot = MobileSnapshot(
            items: [
                WorkItem(title: "A", lane: .inbox, state: .captured, priority: .urgent, summary: "A"),
                WorkItem(title: "B", lane: .inbox, state: .blocked, priority: .high, summary: "B"),
                WorkItem(title: "C", lane: .inbox, state: .done, priority: .urgent, summary: "C")
            ],
            agents: [],
            queuedCaptureCount: 0
        )

        let inbox = try XCTUnwrap(snapshot.laneSummaries.first { $0.id == .inbox })
        XCTAssertEqual(inbox.total, 2)
        XCTAssertEqual(inbox.blocked, 1)
        XCTAssertEqual(inbox.urgent, 1)
    }
}
