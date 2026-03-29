import SwiftUI
import RealityKit

struct BeliefNetworkView: View {
    let beliefs: [Belief]
    let connections: [BeliefConnection]

    private let sphereSize: CGFloat = 60

    var body: some View {
        ZStack {
            // Dark space background
            Color.black.ignoresSafeArea()

            // 3D-ish network of beliefs as floating spheres
            ForEach(beliefs) { belief in
                BeliefSphere(belief: belief, sphereSize: sphereSize)
                    .offset(x: belief.x, y: belief.y, z: belief.z)
            }

            // Connections between related beliefs
            ForEach(connections) { conn in
                ConnectionLine(from: conn.from, to: conn.to)
            }
        }
    }
}

struct BeliefSphere: View {
    let belief: Belief
    let sphereSize: CGFloat

    var body: some View {
        VStack {
            Circle()
                .fill(belief.isCore ? Color.purple : Color.cyan)
                .frame(width: sphereSize, height: sphereSize)
                .opacity(0.8)
                .overlay(
                    Text(String(belief.text.prefix(20)))
                        .font(.caption2)
                        .foregroundColor(.white)
                )
        }
    }
}

struct ConnectionLine: View {
    let from: UUID
    let to: UUID

    var body: some View {
        // Placeholder connection line
        // In a full implementation, this would draw a line between two belief spheres
        Color.white.opacity(0.2)
            .frame(width: 1, height: 100)
    }
}
