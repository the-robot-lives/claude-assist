import Foundation

struct GraphDocument: Decodable, Identifiable, Equatable {
    let id: String
    let slug: String
    let title: String
    let version: Int
    let summary: String?
    let updatedAt: String?
    let modelKind: String?
    let nodes: [GraphNode]
    let edges: [GraphEdge]

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case version
        case summary
        case updatedAt
        case updated_at
        case modelKind
        case model_kind
        case nodes
        case edges
    }

    init(
        id: String,
        slug: String,
        title: String,
        version: Int,
        summary: String?,
        updatedAt: String?,
        modelKind: String?,
        nodes: [GraphNode],
        edges: [GraphEdge]
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.version = version
        self.summary = summary
        self.updatedAt = updatedAt
        self.modelKind = modelKind
        self.nodes = nodes
        self.edges = edges
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        title = try container.decode(String.self, forKey: .title)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        updatedAt = container.decodeStringIfPresent(.updatedAt, .updated_at)
        modelKind = container.decodeStringIfPresent(.modelKind, .model_kind)
        nodes = try container.decodeIfPresent([GraphNode].self, forKey: .nodes) ?? []
        edges = try container.decodeIfPresent([GraphEdge].self, forKey: .edges) ?? []
    }

    var counts: DocumentCounts {
        DocumentCounts(nodes: nodes.count, edges: edges.count)
    }
}

struct DocumentSummary: Decodable, Identifiable, Equatable, Hashable {
    let id: String
    let slug: String?
    let title: String
    let version: Int
    let summary: String?
    let status: String?
    let nodeCount: Int
    let edgeCount: Int
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case version
        case summary
        case status
        case nodeCount
        case edgeCount
        case node_count
        case edge_count
        case updatedAt
        case updated_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        title = try container.decode(String.self, forKey: .title)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        nodeCount = container.decodeIntIfPresent(.nodeCount, .node_count) ?? 0
        edgeCount = container.decodeIntIfPresent(.edgeCount, .edge_count) ?? 0
        updatedAt = container.decodeStringIfPresent(.updatedAt, .updated_at)
    }
}

struct GraphNode: Decodable, Identifiable, Equatable {
    let id: String
    let label: String
    let kind: String
    let parentId: String?
    let description: String?
    let status: String?
    let metrics: NodeMetrics?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case kind
        case parentId
        case parent_id
        case description
        case status
        case metrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? id
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "node"
        parentId = container.decodeStringIfPresent(.parentId, .parent_id)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        metrics = try container.decodeIfPresent(NodeMetrics.self, forKey: .metrics)
    }

    init(id: String, label: String, kind: String, parentId: String? = nil, description: String? = nil, status: String? = nil, metrics: NodeMetrics? = nil) {
        self.id = id
        self.label = label
        self.kind = kind
        self.parentId = parentId
        self.description = description
        self.status = status
        self.metrics = metrics
    }
}

struct NodeMetrics: Decodable, Equatable {
    let complexity: Double?
    let churn: Double?
    let risk: Double?
}

struct GraphEdge: Decodable, Identifiable, Equatable {
    let id: String
    let sourceId: String
    let targetId: String
    let kind: String
    let label: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceId
        case source_id
        case targetId
        case target_id
        case kind
        case label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sourceId = container.decodeStringIfPresent(.sourceId, .source_id) ?? ""
        targetId = container.decodeStringIfPresent(.targetId, .target_id) ?? ""
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "edge"
        label = try container.decodeIfPresent(String.self, forKey: .label)
    }
}

struct DocumentCounts: Equatable {
    let nodes: Int
    let edges: Int
}
