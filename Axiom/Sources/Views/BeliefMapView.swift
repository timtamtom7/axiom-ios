import SwiftUI

struct BeliefMapView: View {
    @EnvironmentObject var databaseService: DatabaseService

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if databaseService.allBeliefs.isEmpty {
                    EmptyStateView(
                        icon: "circle.hexagongrid",
                        title: "No Beliefs to Map",
                        subtitle: "Add beliefs to see how they connect.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    GeometryReader { geometry in
                        let beliefs = databaseService.allBeliefs
                        let connections = databaseService.allConnections
                        let centerX = geometry.size.width / 2
                        let centerY = geometry.size.height / 2
                        let radius = min(geometry.size.width, geometry.size.height) * 0.3

                        ZStack {
                            // Connection lines — only for actual connections
                            ForEach(connections) { conn in
                                if let fromIndex = beliefs.firstIndex(where: { $0.id == conn.fromBeliefId }),
                                   let toIndex = beliefs.firstIndex(where: { $0.id == conn.toBeliefId }) {
                                    let p1 = position(for: fromIndex, count: beliefs.count, centerX: centerX, centerY: centerY, radius: radius)
                                    let p2 = position(for: toIndex, count: beliefs.count, centerX: centerX, centerY: centerY, radius: radius)
                                    ConnectionLine(from: p1, to: p2, strength: conn.strength)
                                }
                            }

                            // Belief nodes
                            ForEach(Array(beliefs.enumerated()), id: \.element.id) { index, belief in
                                let pos = position(for: index, count: beliefs.count, centerX: centerX, centerY: centerY, radius: radius)
                                NavigationLink(destination: BeliefDetailView(belief: belief)) {
                                    BeliefNode(belief: belief)
                                }
                                .buttonStyle(.plain)
                                .position(pos)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Belief Map")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func position(for index: Int, count: Int, centerX: CGFloat, centerY: CGFloat, radius: CGFloat) -> CGPoint {
        guard count > 0 else { return CGPoint(x: centerX, y: centerY) }
        let angle = (2 * .pi / Double(count)) * Double(index) - .pi / 2
        return CGPoint(
            x: centerX + radius * CGFloat(cos(angle)),
            y: centerY + radius * CGFloat(sin(angle))
        )
    }
}

struct BeliefNode: View {
    let belief: Belief

    var body: some View {
        VStack(spacing: Theme.spacingXS) {
            ZStack {
                Circle()
                    .fill(Theme.scoreColor(for: belief.score).opacity(0.2))
                    .frame(width: nodeSize, height: nodeSize)

                Circle()
                    .stroke(Theme.scoreColor(for: belief.score), lineWidth: 2)
                    .frame(width: nodeSize, height: nodeSize)

                if belief.isCore {
                    Circle()
                        .stroke(Theme.accentGold, lineWidth: 3)
                        .frame(width: nodeSize + 4, height: nodeSize + 4)
                }

                Image(systemName: "brain")
                    .font(.system(size: nodeSize * 0.35))
                    .foregroundColor(Theme.scoreColor(for: belief.score))
            }

            Text(belief.text)
                .font(.caption2)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }

    private var nodeSize: CGFloat {
        let base: CGFloat = 60
        let evidenceCount = belief.evidenceItems.count
        return base + CGFloat(min(evidenceCount, 10)) * 4
    }
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let strength: Double

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Theme.accentBlue.opacity(strength), lineWidth: CGFloat(1 + strength * 2))
    }
}

#Preview {
    BeliefMapView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
