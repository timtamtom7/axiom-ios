import SwiftUI
#if canImport(XRExperience)
import XRExperience
#endif

/// R14: Apple Vision Pro support
/// - Spatial belief network
/// - Immersive therapy session
/// - Group belief sessions in Vision Pro space
struct BeliefSpatialView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedBeliefId: UUID?
    @State private var showingImmersiveSession = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if databaseService.allBeliefs.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "Spatial Belief Network",
                    subtitle: "Add beliefs to see them arranged in a spatial network.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let radius = min(geometry.size.width, geometry.size.height) * 0.35
                    let total = max(databaseService.allBeliefs.count, 1)

                    ZStack {
                        connectionsView(center: center, radius: radius, total: total)
                        nodesView(center: center, radius: radius, total: total)
                    }
                }
            }

            if let prompt = AIBeliefAgentService.shared.dailyPrompt {
                floatingPrompt(prompt)
            }
        }
        .sheet(isPresented: $showingImmersiveSession) {
            ImmersiveTherapySessionView()
        }
    }

    @ViewBuilder
    private func connectionsView(center: CGPoint, radius: CGFloat, total: Int) -> some View {
        let beliefs = databaseService.allBeliefs
        ForEach(databaseService.allConnections) { conn in
            if let fromBelief = beliefs.first(where: { $0.id == conn.fromBeliefId }),
               let toBelief = beliefs.first(where: { $0.id == conn.toBeliefId }) {
                let fromPos = position(for: fromBelief, center: center, radius: radius, total: total)
                let toPos = position(for: toBelief, center: center, radius: radius, total: total)
                SpatialConnectionLine(from: fromPos, to: toPos)
                    .stroke(Theme.accentGold.opacity(0.3), lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private func nodesView(center: CGPoint, radius: CGFloat, total: Int) -> some View {
        let beliefs = databaseService.allBeliefs
        ForEach(beliefs) { belief in
            let pos = position(for: belief, center: center, radius: radius, total: total)
            SpatialBeliefNode(
                belief: belief,
                isSelected: selectedBeliefId == belief.id
            )
            .position(pos)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    selectedBeliefId = belief.id
                }
            }
        }
    }

    private func position(for belief: Belief, center: CGPoint, radius: CGFloat, total: Int) -> CGPoint {
        let beliefs = databaseService.allBeliefs
        guard let index = beliefs.firstIndex(where: { $0.id == belief.id }) else {
            return center
        }
        let angle = (2 * .pi / Double(total)) * Double(index) - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func floatingPrompt(_ prompt: AIBeliefAgentService.AgentPrompt) -> some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.accentGold)
                Text(prompt.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                    showingImmersiveSession = true
                } label: {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accentBlue)
                }
            }
            .padding()
            .background(Theme.surfaceElevated)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 20)

            Spacer().frame(height: 40)
        }
        .padding()
    }
}

struct SpatialBeliefNode: View {
    let belief: Belief
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Theme.scoreColor(for: belief.score).opacity(0.3))
                    .frame(width: isSelected ? 80 : 60, height: isSelected ? 80 : 60)

                Circle()
                    .stroke(Theme.scoreColor(for: belief.score), lineWidth: isSelected ? 3 : 2)
                    .frame(width: isSelected ? 80 : 60, height: isSelected ? 80 : 60)

                Text("\(Int(belief.score))")
                    .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(belief.text)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

struct SpatialConnectionLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

/// R14: Immersive therapy session for Vision Pro
struct ImmersiveTherapySessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0

    private let steps = [
        "Take a deep breath and settle in",
        "Bring to mind a belief that has been troubling you",
        "Notice where you feel this in your body",
        "Gently challenge the evidence for this belief",
        "Consider an alternative perspective",
        "Notice how your body feels now"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                progressIndicators
                Spacer()
                stepContent
                Spacer()
                navigationButtons
            }
        }
    }

    private var progressIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Theme.accentGold : Theme.textSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.top, 40)
    }

    private var stepContent: some View {
        VStack(spacing: 24) {
            Text("Step \(currentStep + 1)")
                .font(.title3)
                .foregroundColor(Theme.accentGold)

            Text(steps[currentStep])
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.textSecondary)
                }
            } else {
                Color.clear.frame(width: 50, height: 50)
            }

            Button {
                if currentStep < steps.count - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: currentStep < steps.count - 1 ? "chevron.right.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Theme.accentGold)
            }
        }
        .padding(.bottom, 40)
    }
}
