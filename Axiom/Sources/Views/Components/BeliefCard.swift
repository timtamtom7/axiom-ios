import SwiftUI

struct BeliefCard: View {
    let belief: Belief
    var connectionCount: Int = 0
    @State private var displayedScore: Double = 0
    @State private var scorePulse: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack(spacing: Theme.spacingXS) {
                        if belief.isCore {
                            Text("CORE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.accentGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accentGold.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Text(belief.text)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text("Updated \(belief.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                ScoreBadge(score: displayedScore)
                    .scaleEffect(scorePulse)
            }

            HStack(spacing: Theme.spacingL) {
                Label("\(belief.supportingCount)", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(Theme.accentGreen)

                Label("\(belief.contradictingCount)", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(Theme.accentRed)

                if connectionCount > 0 {
                    Label("\(connectionCount)", systemImage: "link")
                        .font(.caption)
                        .foregroundColor(Theme.accentBlue)
                }

                if let checkIn = belief.checkInScheduledAt, checkIn > Date() {
                    Label("Check-in", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(Theme.accentGold)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
        .onAppear {
            animateScore(to: belief.score)
        }
        .onChange(of: belief.score) { newValue in
            let oldValue = displayedScore
            if abs(newValue - oldValue) > 1 {
                // Pulse on significant score change
                withAnimation(.easeInOut(duration: 0.1)) {
                    scorePulse = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        scorePulse = 1.0
                    }
                }
                animateScore(to: newValue)
            }
        }
    }

    private func animateScore(to target: Double) {
        let steps = 8
        let stepDuration = 0.12 / Double(steps)
        let increment = (target - displayedScore) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    displayedScore += increment
                }
            }
        }
    }
}

#Preview {
    VStack {
        BeliefCard(belief: .preview, connectionCount: 2)
        BeliefCard(belief: Belief(text: "I'm not creative enough"), connectionCount: 0)
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
