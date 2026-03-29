import SwiftUI
import RealityKit

struct SessionView: View {
    @State private var beliefs: [Belief] = []
    @State private var expandedBeliefId: UUID?

    var body: some View {
        ZStack {
            // Immersive dark space
            Color.black.ignoresSafeArea()

            // Floating belief cards in space
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    ForEach(beliefs) { belief in
                        BeliefCardView(
                            belief: belief,
                            isExpanded: expandedBeliefId == belief.id
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if expandedBeliefId == belief.id {
                                    expandedBeliefId = nil
                                } else {
                                    expandedBeliefId = belief.id
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
            }

            // Voice input hint at the bottom
            VStack {
                Spacer()
                Text("Say \"Hey Siri, add a belief in Axiom\"")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
    }
}

struct BeliefCardView: View {
    let belief: Belief
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(belief.isCore ? Color.purple : Color.cyan)
                    .frame(width: 12, height: 12)

                Text(belief.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(isExpanded ? nil : 2)

                Spacer()
            }

            if isExpanded {
                // Expand evidence
                if !belief.evidence.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Evidence:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        ForEach(belief.evidence, id: \.self) { evidence in
                            Text("• \(evidence)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}
