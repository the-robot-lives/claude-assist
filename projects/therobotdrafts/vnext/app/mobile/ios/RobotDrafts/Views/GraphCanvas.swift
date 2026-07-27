import SwiftUI

struct GraphCanvas: View {
    let document: GraphDocument

    var body: some View {
        Canvas { context, size in
            let nodes = Array(document.nodes.prefix(48))
            guard !nodes.isEmpty else { return }

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.34
            let count = max(nodes.count, 1)
            var positions: [String: CGPoint] = [:]

            for (index, node) in nodes.enumerated() {
                let angle = Double(index) / Double(count) * Double.pi * 2
                let distance = node.parentId == nil ? radius * 0.38 : radius
                let point = CGPoint(
                    x: center.x + cos(angle) * distance,
                    y: center.y + sin(angle) * distance
                )
                positions[node.id] = point
            }

            for edge in document.edges.prefix(96) {
                guard let source = positions[edge.sourceId],
                      let target = positions[edge.targetId]
                else { continue }

                var path = Path()
                path.move(to: source)
                path.addLine(to: target)
                context.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 1)
            }

            for node in nodes {
                guard let point = positions[node.id] else { continue }
                let bubble = CGRect(x: point.x - 18, y: point.y - 18, width: 36, height: 36)
                context.fill(Path(ellipseIn: bubble), with: .color(fill(for: node.kind)))
                context.stroke(Path(ellipseIn: bubble), with: .color(.white.opacity(0.35)), lineWidth: 1)
            }
        }
        .background(
            LinearGradient(
                colors: [Brand.panel, Color(red: 0.05, green: 0.08, blue: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .accessibilityLabel("\(document.nodes.count) nodes and \(document.edges.count) edges")
    }

    private func fill(for kind: String) -> Color {
        switch kind {
        case "database": return Brand.secondary
        case "agent": return Brand.good
        case "function": return Brand.primary
        case "service": return Color(red: 0.82, green: 0.43, blue: 0.34)
        default: return Color(red: 0.55, green: 0.61, blue: 0.66)
        }
    }
}
