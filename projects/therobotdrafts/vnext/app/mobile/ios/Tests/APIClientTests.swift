import XCTest
@testable import RobotDrafts

final class APIClientTests: XCTestCase {
    func testURLConstructionTrimsSlashes() {
        let client = APIClient(baseURL: URL(string: "https://draft.therobotplans.com/")!)
        XCTAssertEqual(
            client.url(path: "/api/v1/holograph/docs").absoluteString,
            "https://draft.therobotplans.com/api/v1/holograph/docs"
        )
    }
}
