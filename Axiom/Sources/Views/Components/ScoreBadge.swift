import SwiftUI

struct ScoreBadge: View {
    let score: Double

    var body: some View {
        Text("\(Int(score))")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Theme.scoreColor(for: score))
            .clipShape(Circle())
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
