import SwiftUI

struct ArchivedBeliefsView: View {
    let beliefs: [Belief]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if beliefs.isEmpty {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.textSecondary)
                        Text("No Archived Beliefs")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        Text("Beliefs you let go of will appear here as obituaries — a record of what you used to believe.")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.screenMargin)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            ForEach(beliefs) { belief in
                                ArchivedBeliefCard(belief: belief)
                            }
                        }
                        .padding(.horizontal, Theme.screenMargin)
                        .padding(.top, Theme.spacingM)
                    }
                }
            }
            .navigationTitle("Belief Obituaries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ArchivedBeliefCard: View {
    let belief: Belief

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "archivebox")
                    .foregroundColor(Theme.textSecondary)
                Text("Archived")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                Spacer()
                if let date = belief.archivedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Text(belief.text)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if let reason = belief.archiveReason, !reason.isEmpty {
                Text("Obituary: \(reason)")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            }

            if let archivedScore = belief.archivedScore {
                HStack(spacing: Theme.spacingM) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Buried")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                        Text("\(Int(archivedScore))")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.scoreColor(for: archivedScore))
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                        let delta = belief.score - archivedScore
                        HStack(spacing: 2) {
                            Text("\(Int(belief.score))")
                                .font(.system(.callout, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.scoreColor(for: belief.score))
                            if abs(delta) > 1 {
                                Text("(\(delta > 0 ? "+" : "")\(Int(delta)))")
                                    .font(.caption2)
                                    .foregroundColor(delta > 0 ? Theme.accentGreen : Theme.accentRed)
                            }
                        }
                    }

                    Spacer()
                }
            } else {
                HStack {
                    ScoreBadge(score: belief.score)
                    Text("Score at archive")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    ArchivedBeliefsView(beliefs: [
        Belief(
            text: "I am bad at relationships",
            isArchived: true,
            archivedAt: Date().addingTimeInterval(-86400 * 30),
            archiveReason: "The evidence no longer supports this. I've had many healthy relationships.",
            archivedScore: 68
        )
    ])
    .preferredColorScheme(.dark)
}
