import SwiftUI

struct BeliefCard: View {
    let belief: Belief

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(belief.text)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text("Updated \(belief.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                ScoreBadge(score: belief.score)
            }

            HStack(spacing: Theme.spacingL) {
                Label("\(belief.supportingCount)", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(Theme.accentGreen)

                Label("\(belief.contradictingCount)", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(Theme.accentRed)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        BeliefCard(belief: .preview)
        BeliefCard(belief: Belief(text: "I'm not creative enough"))
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
