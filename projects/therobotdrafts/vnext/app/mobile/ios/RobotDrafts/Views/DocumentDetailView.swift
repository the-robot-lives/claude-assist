import SwiftUI

struct DocumentDetailView: View {
    @EnvironmentObject private var documentsStore: DocumentsStore

    let document: GraphDocument?

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(document)
                        GraphCanvas(document: document)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Brand.line)
                            )
                        nodeList(document)
                    }
                    .padding()
                    .frame(maxWidth: 920, alignment: .leading)
                }
                .background(Brand.page)
            } else {
                ContentUnavailableView("Select a Document", systemImage: "doc.text")
                    .background(Brand.page)
            }
        }
        .navigationTitle(document?.title ?? "Document")
        .overlay(alignment: .bottom) {
            if let error = documentsStore.errorMessage {
                Text(error)
                    .font(.footnote)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding()
            }
        }
    }

    private func header(_ document: GraphDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.largeTitle.bold())
                        .lineLimit(3)
                    if let summary = document.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("v\(document.version)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Brand.secondary)
            }

            HStack {
                MetricPill(title: "Nodes", value: "\(document.nodes.count)", icon: "circle.hexagongrid.fill")
                MetricPill(title: "Edges", value: "\(document.edges.count)", icon: "arrow.triangle.branch")
                MetricPill(title: "Model", value: document.modelKind ?? "graph", icon: "square.stack.3d.up.fill")
            }
        }
    }

    private func nodeList(_ document: GraphDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nodes")
                .font(.title3.bold())

            LazyVStack(spacing: 8) {
                ForEach(document.nodes.prefix(40)) { node in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: node.kind))
                            .foregroundStyle(color(for: node.kind))
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.label)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(node.kind)
                                if let risk = node.metrics?.risk {
                                    Text("risk \(risk, specifier: "%.1f")")
                                }
                            }
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Brand.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    private func icon(for kind: String) -> String {
        switch kind {
        case "database": return "cylinder.split.1x2.fill"
        case "service": return "gearshape.2.fill"
        case "class": return "shippingbox.fill"
        case "interface": return "point.3.connected.trianglepath.dotted"
        case "function": return "function"
        case "agent": return "sparkles"
        default: return "circle.hexagonpath.fill"
        }
    }

    private func color(for kind: String) -> Color {
        switch kind {
        case "database": return Brand.secondary
        case "agent": return Brand.good
        case "function": return Brand.primary
        default: return .white.opacity(0.82)
        }
    }
}
