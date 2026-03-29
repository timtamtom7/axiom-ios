import SwiftUI

/// R22: Leaderboard view showing top belief debaters for AxiomMac
struct MacLeaderboardView: View {
    @State private var entries: [SocialChallengeService.LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var selectedPeriod: TimePeriod = .allTime

    enum TimePeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            leaderboardContent
        }
        .background(Theme.background)
        .onAppear { loadLeaderboard() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Belief Debaters")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)

                    Text("Compete by challenging friends to debates")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                .onChange(of: selectedPeriod) { _, _ in loadLeaderboard() }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.top, Theme.screenMargin)
        }
        .padding(.bottom, Theme.spacingM)
        .background(Theme.surface)
    }

    // MARK: - Leaderboard Content

    @ViewBuilder
    private var leaderboardContent: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if entries.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Top 3 podium
                    podiumSection
                    Divider()
                        .background(Theme.border)
                        .padding(.horizontal)

                    // Rest of leaderboard
                    remainingEntries
                }
                .padding(.vertical, Theme.spacingL)
            }
        }
    }

    // MARK: - Podium

    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // 2nd place
            PodiumSlot(
                rank: 2,
                entry: entries[safe: 1],
                height: 100
            )

            // 1st place
            PodiumSlot(
                rank: 1,
                entry: entries[safe: 0],
                height: 130
            )

            // 3rd place
            PodiumSlot(
                rank: 3,
                entry: entries[safe: 2],
                height: 80
            )
        }
        .padding(.horizontal, Theme.screenMargin)
    }

    // MARK: - Remaining Entries

    private var remainingEntries: some View {
        LazyVStack(spacing: Theme.spacingS) {
            ForEach(Array(entries.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(
                    entry: entry,
                    rank: index + 4
                )
            }
        }
        .padding(.horizontal, Theme.screenMargin)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))

            VStack(spacing: Theme.spacingS) {
                Text("No Rankings Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)

                Text("Challenge friends to belief debates to start climbing the leaderboard")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                // Navigate to challenge creation
            } label: {
                Label("Start a Challenge", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentGold)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadLeaderboard() {
        isLoading = true
        Task {
            do {
                entries = try await SocialChallengeService.shared.fetchLeaderboard()
            } catch {
                print("Failed to load leaderboard: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Podium Slot

struct PodiumSlot: View {
    let rank: Int
    let entry: SocialChallengeService.LeaderboardEntry?
    var height: CGFloat = 100

    private var medalColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.78, green: 0.50, blue: 0.20) // Bronze
        default: return Theme.textSecondary
        }
    }

    var body: some View {
        if let entry = entry {
            VStack(spacing: Theme.spacingS) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.accentGold.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Text(String(entry.name.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accentGold)
                }

                // Name
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                // Score
                Text("\(entry.score) pts")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                // Medal
                ZStack {
                    Circle()
                        .fill(medalColor)
                        .frame(width: 28, height: 28)

                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                // Podium base
                RoundedRectangle(cornerRadius: 6)
                    .fill(medalColor.opacity(0.3))
                    .frame(height: height)
                    .overlay(
                        Text("\(entry.beliefsResolved)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textPrimary),
                        alignment: .bottom
                    )
                    .padding(.top, Theme.spacingXS)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: Theme.spacingS) {
                Circle()
                    .stroke(Theme.border, lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "questionmark")
                            .foregroundColor(Theme.textSecondary)
                    )

                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.surfaceElevated)
                    .frame(height: height)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: SocialChallengeService.LeaderboardEntry
    let rank: Int

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            // Rank
            Text("#\(rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(rankColor)
                .frame(width: 36, alignment: .leading)

            // Avatar
            Circle()
                .fill(Theme.accentBlue.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(entry.name.prefix(1)).uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.accentBlue)
                )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)

                Text("\(entry.beliefsResolved) beliefs resolved")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            // Score
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accentGold)
                Text("\(entry.score)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Theme.accentGold
        case 2: return Theme.textSecondary
        case 3: return Color(red: 0.78, green: 0.50, blue: 0.20)
        default: return Theme.textSecondary
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MacLeaderboardView()
}
