import SwiftUI
import Combine

struct BeliefMapView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var nodeVelocities: [UUID: CGPoint] = [:]
    @State private var isSimulating = true
    @State private var timer: AnyCancellable?

    private let repulsionStrength: CGFloat = 8000
    private let attractionStrength: CGFloat = 0.04
    private let damping: CGFloat = 0.85
    private let centerGravity: CGFloat = 0.02

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if databaseService.allBeliefs.isEmpty {
                    EmptyStateView(
                        icon: "circle.hexagongrid",
                        title: "Your Belief Map",
                        subtitle: "Add beliefs in the first tab, then come back here to see how they connect and influence each other.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    GeometryReader { geometry in
                        let size = CGSize(width: geometry.size.width, height: geometry.size.height)
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)

                        ZStack {
                            // Connection lines
                            ForEach(databaseService.allConnections) { conn in
                                if let from = nodePositions[conn.fromBeliefId],
                                   let to = nodePositions[conn.toBeliefId] {
                                    ConnectionLine(from: from, to: to, strength: conn.strength)
                                        .transition(.opacity)
                                }
                            }

                            // Belief nodes
                            ForEach(databaseService.allBeliefs) { belief in
                                if let position = nodePositions[belief.id] {
                                    NavigationLink(destination: BeliefDetailView(belief: belief)) {
                                        BeliefNode(belief: belief)
                                    }
                                    .buttonStyle(.plain)
                                    .position(position)
                                }
                            }
                        }
                        .onAppear {
                            initializePositions(in: size, center: center)
                            startSimulation(in: size)
                        }
                        .onChange(of: databaseService.allBeliefs.count) { _, newCount in
                            if newCount > nodePositions.count {
                                initializePositions(in: size, center: center)
                            }
                        }
                        .onDisappear {
                            stopSimulation()
                        }
                    }
                }
            }
            .navigationTitle("Belief Map")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func initializePositions(in size: CGSize, center: CGPoint) {
        let beliefs = databaseService.allBeliefs
        var newPositions: [UUID: CGPoint] = [:]
        var newVelocities: [UUID: CGPoint] = [:]

        for (index, belief) in beliefs.enumerated() {
            if let existing = nodePositions[belief.id] {
                newPositions[belief.id] = existing
                newVelocities[belief.id] = nodeVelocities[belief.id] ?? .zero
            } else {
                // Start in a spiral pattern from center
                let angle = Double(index) * (2 * .pi / max(1, Double(beliefs.count)))
                let radius = CGFloat(index) * 30 + 20
                let pos = CGPoint(
                    x: center.x + radius * CGFloat(cos(angle)),
                    y: center.y + radius * CGFloat(sin(angle))
                )
                newPositions[belief.id] = pos
                newVelocities[belief.id] = .zero
            }
        }

        nodePositions = newPositions
        nodeVelocities = newVelocities
    }

    private func startSimulation(in size: CGSize) {
        stopSimulation()
        isSimulating = true
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard isSimulating else { return }
                simulationStep(center: center, size: size)
            }
    }

    private func stopSimulation() {
        timer?.cancel()
        timer = nil
        isSimulating = false
    }

    private func simulationStep(center: CGPoint, size: CGSize) {
        let beliefs = databaseService.allBeliefs
        let connections = databaseService.allConnections
        var forces: [UUID: CGPoint] = [:]

        // Initialize forces
        for belief in beliefs {
            forces[belief.id] = .zero
        }

        // Repulsion between all pairs of nodes
        for i in 0..<beliefs.count {
            for j in (i+1)..<beliefs.count {
                guard let posI = nodePositions[beliefs[i].id],
                      let posJ = nodePositions[beliefs[j].id] else { continue }

                let delta = CGPoint(x: posI.x - posJ.x, y: posI.y - posJ.y)
                let dist = max(sqrt(delta.x * delta.x + delta.y * delta.y), 1)
                let forceMag = repulsionStrength / (dist * dist)

                if dist > 0 {
                    let fx = (delta.x / dist) * forceMag
                    let fy = (delta.y / dist) * forceMag
                    forces[beliefs[i].id] = CGPoint(
                        x: forces[beliefs[i].id]!.x + fx,
                        y: forces[beliefs[i].id]!.y + fy
                    )
                    forces[beliefs[j].id] = CGPoint(
                        x: forces[beliefs[j].id]!.x - fx,
                        y: forces[beliefs[j].id]!.y - fy
                    )
                }
            }
        }

        // Attraction along connections (spring force)
        for conn in connections {
            guard let fromPos = nodePositions[conn.fromBeliefId],
                  let toPos = nodePositions[conn.toBeliefId] else { continue }

            let delta = CGPoint(x: toPos.x - fromPos.x, y: toPos.y - fromPos.y)
            let dist = sqrt(delta.x * delta.x + delta.y * delta.y)
            let idealLength: CGFloat = 150
            let displacement = dist - idealLength
            let forceMag = attractionStrength * displacement

            if dist > 0 {
                let fx = (delta.x / dist) * forceMag
                let fy = (delta.y / dist) * forceMag
                forces[conn.fromBeliefId] = CGPoint(
                    x: forces[conn.fromBeliefId]!.x + fx,
                    y: forces[conn.fromBeliefId]!.y + fy
                )
                forces[conn.toBeliefId] = CGPoint(
                    x: forces[conn.toBeliefId]!.x - fx,
                    y: forces[conn.toBeliefId]!.y - fy
                )
            }
        }

        // Center gravity — gently pull toward center
        for belief in beliefs {
            guard let pos = nodePositions[belief.id] else { continue }
            let delta = CGPoint(x: center.x - pos.x, y: center.y - pos.y)
            forces[belief.id] = CGPoint(
                x: forces[belief.id]!.x + delta.x * centerGravity,
                y: forces[belief.id]!.y + delta.y * centerGravity
            )
        }

        // Apply forces and update positions
        var totalMovement: CGFloat = 0
        var newPositions: [UUID: CGPoint] = [:]
        var newVelocities: [UUID: CGPoint] = [:]

        for belief in beliefs {
            guard let vel = nodeVelocities[belief.id],
                  let force = forces[belief.id],
                  let pos = nodePositions[belief.id] else { continue }

            let newVel = CGPoint(
                x: (vel.x + force.x) * damping,
                y: (vel.y + force.y) * damping
            )
            var newPos = CGPoint(
                x: pos.x + newVel.x,
                y: pos.y + newVel.y
            )

            // Clamp to bounds with padding
            let padding: CGFloat = 60
            newPos.x = min(max(newPos.x, padding), size.width - padding)
            newPos.y = min(max(newPos.y, padding), size.height - padding)

            let movement = sqrt(newVel.x * newVel.x + newVel.y * newVel.y)
            totalMovement += movement

            newPositions[belief.id] = newPos
            newVelocities[belief.id] = newVel
        }

        withAnimation(.linear(duration: 0)) {
            nodePositions = newPositions
            nodeVelocities = newVelocities
        }

        // Stop simulation if settled
        if totalMovement < 0.5 && timer != nil {
            // Keep running lightly for responsiveness
        }
    }
}

struct BeliefNode: View {
    let belief: Belief
    @State private var isExpanded = false

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
        .scaleEffect(isExpanded ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        .onTapGesture {
            isExpanded.toggle()
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
