import SwiftUI

struct ScoreBadge: View {
    let score: Double

    private var scoreDescription: String {
        if score < 40 {
            return "evidence leans against this belief"
        } else if score < 70 {
            return "evidence is mixed"
        } else {
            return "evidence supports this belief"
        }
    }

    var body: some View {
        Text("\(Int(score))")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(Theme.background)
            .frame(width: Theme.scoreBadgeSize, height: Theme.scoreBadgeSize)
            .background(Theme.scoreColor(for: score))
            .clipShape(Circle())
            .accessibilityLabel("Evidence score \(Int(score)) out of 100, \(scoreDescription)")
    }
}

#Preview {
    HStack(spacing: 20) {
        ScoreBadge(score: 25)
        ScoreBadge(score: 55)
        ScoreBadge(score: 85)
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
