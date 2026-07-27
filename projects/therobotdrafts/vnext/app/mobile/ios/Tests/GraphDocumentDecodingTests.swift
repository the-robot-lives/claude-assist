import XCTest
@testable import RobotDrafts

final class GraphDocumentDecodingTests: XCTestCase {
    func testDocumentEnvelopeDecodesCanonicalGraphShape() throws {
        let json = """
        {
          "data": {
            "id": "sample",
            "slug": "sample",
            "title": "Sample",
            "version": 3,
            "updatedAt": "2026-07-27T10:00:00Z",
            "modelKind": "uml",
            "summary": "A small graph",
            "nodes": [
              {
                "id": "n1",
                "label": "Backend",
                "kind": "service",
                "metrics": { "complexity": 2, "churn": 1, "risk": 0.4 }
              }
            ],
            "edges": [
              { "id": "e1", "sourceId": "n1", "targetId": "n1", "kind": "depends_on" }
            ]
          },
          "meta": { "source": "fixture" }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(APIEnvelope<GraphDocument>.self, from: json)
        let document = try XCTUnwrap(envelope.data)

        XCTAssertEqual(document.title, "Sample")
        XCTAssertEqual(document.version, 3)
        XCTAssertEqual(document.counts.nodes, 1)
        XCTAssertEqual(document.counts.edges, 1)
        XCTAssertEqual(document.nodes.first?.metrics?.risk, 0.4)
    }

    func testSummaryDecodesSnakeAndCamelCounts() throws {
        let snake = """
        { "id": "a", "slug": "a", "title": "A", "version": 1, "node_count": 7, "edge_count": 9 }
        """.data(using: .utf8)!
        let camel = """
        { "id": "b", "slug": "b", "title": "B", "version": 2, "nodeCount": 3, "edgeCount": 5 }
        """.data(using: .utf8)!

        let a = try JSONDecoder().decode(DocumentSummary.self, from: snake)
        let b = try JSONDecoder().decode(DocumentSummary.self, from: camel)

        XCTAssertEqual(a.nodeCount, 7)
        XCTAssertEqual(a.edgeCount, 9)
        XCTAssertEqual(b.nodeCount, 3)
        XCTAssertEqual(b.edgeCount, 5)
    }
}
