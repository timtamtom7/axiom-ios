import SwiftUI

/// A stylized illustration of interconnected belief nodes, used for empty states.
struct BeliefNetworkIllustration: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 200

            let nodes: [(CGPoint, CGFloat, Color)] = [
                (center, 18 * scale, Theme.accentGold),
                (CGPoint(x: center.x - 50 * scale, y: center.y - 45 * scale), 12 * scale, Theme.accentGold.opacity(0.6)),
                (CGPoint(x: center.x + 50 * scale, y: center.y - 45 * scale), 12 * scale, Theme.accentGold.opacity(0.6)),
                (CGPoint(x: center.x - 55 * scale, y: center.y + 40 * scale), 12 * scale, Theme.accentGold.opacity(0.6)),
                (CGPoint(x: center.x + 55 * scale, y: center.y + 40 * scale), 12 * scale, Theme.accentGold.opacity(0.6)),
                (CGPoint(x: center.x, y: center.y - 60 * scale), 10 * scale, Theme.accentGold.opacity(0.4)),
                (CGPoint(x: center.x, y: center.y + 60 * scale), 10 * scale, Theme.accentGold.opacity(0.4)),
            ]

            let connections: [(Int, Int)] = [
                (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (2, 4), (3, 6), (4, 6), (1, 5), (2, 5)
            ]

            // Draw connections
            for (i, j) in connections {
                let p1 = nodes[i].0
                let p2 = nodes[j].0
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                context.stroke(path, with: .color(Theme.accentBlue.opacity(0.3)), lineWidth: 1.5 * scale)
            }

            // Draw nodes
            for (pos, radius, color) in nodes {
                // Outer glow
                var glowPath = Path()
                glowPath.addEllipse(in: CGRect(
                    x: pos.x - radius * 1.5,
                    y: pos.y - radius * 1.5,
                    width: radius * 3,
                    height: radius * 3
                ))
                context.fill(glowPath, with: .radialGradient(
                    Gradient(colors: [color.opacity(0.2), .clear]),
                    center: pos,
                    startRadius: radius * 0.5,
                    endRadius: radius * 2
                ))

                // Node fill
                var fillPath = Path()
                fillPath.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(fillPath, with: .color(color.opacity(0.15)))

                // Node stroke
                context.stroke(fillPath, with: .color(color), lineWidth: 2 * scale)

                // Brain icon for center node
                if radius > 15 * scale {
                    let iconSize = radius * 0.8
                    let brainPath = makeBrainPath(center: pos, size: iconSize)
                    context.stroke(brainPath, with: .color(color), lineWidth: 1.5 * scale)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func makeBrainPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let r = size / 2

        // Simplified brain squiggle
        path.move(to: CGPoint(x: center.x - r * 0.5, y: center.y))
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - r * 0.4),
            control: CGPoint(x: center.x - r * 0.3, y: center.y - r * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x + r * 0.5, y: center.y),
            control: CGPoint(x: center.x + r * 0.3, y: center.y - r * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + r * 0.4),
            control: CGPoint(x: center.x + r * 0.3, y: center.y + r * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - r * 0.5, y: center.y),
            control: CGPoint(x: center.x - r * 0.3, y: center.y + r * 0.5)
        )

        // Center divider
        path.move(to: CGPoint(x: center.x, y: center.y - r * 0.4))
        path.addLine(to: CGPoint(x: center.x, y: center.y + r * 0.4))

        return path
    }
}

#Preview {
    BeliefNetworkIllustration(size: 200)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
