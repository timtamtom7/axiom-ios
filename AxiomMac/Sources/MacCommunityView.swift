import SwiftUI

/// macOS community view using NavigationSplitView for the Axiom app.
struct MacCommunityView: View {
    @StateObject private var communityStore = CommunityStore.shared
    @State private var selectedTab: CommunityTab = .anonymousFeed
    @State private var selectedBelief: SharedBelief?
    @State private var showingPostSheet = false
    @State private var searchText = ""

    enum CommunityTab: String, CaseIterable {
        case anonymousFeed = "Anonymous Feed"
        case debates = "Debates"
        case leaderboard = "Evidence Leaderboard"
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                tabSelector
                Divider()
                feedContent
            }
            .frame(minWidth: 300, idealWidth: 350)
            .background(Theme.surface)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingPostSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share belief anonymously")
                .accessibilityHint("Opens a sheet to share a belief with the community")
            }
        }
        .sheet(isPresented: $showingPostSheet) {
            MacCommunityPostSheet()
        }
    }

    private var tabSelector: some View {
        VStack(spacing: Theme.spacingS) {
            ForEach(CommunityTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation { selectedTab = tab }
                } label: {
                    HStack {
                        Image(systemName: tabIcon(for: tab))
                            .font(.system(size: 14))
                            .frame(width: 20)
                        Text(tab.rawValue)
                            .font(.subheadline)
                        Spacer()
                        if selectedTab == tab {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(Theme.accentGold)
                        }
                    }
                    .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                    .background(selectedTab == tab ? Theme.accentGold.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.screenMargin)
    }

    private func tabIcon(for tab: CommunityTab) -> String {
        switch tab {
        case .anonymousFeed: return "person.fill.questionmark"
        case .debates: return "bubble.left.and.bubble.right.fill"
        case .leaderboard: return "trophy.fill"
        }
    }

    @ViewBuilder
    private var feedContent: some View {
        switch selectedTab {
        case .anonymousFeed:
            anonymousFeedList
        case .debates:
            debatesList
        case .leaderboard:
            leaderboardList
        }
    }

    private var anonymousFeedList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(filteredSharedBeliefs) { belief in
                    MacCommunityBeliefRow(belief: belief, isSelected: selectedBelief?.id == belief.id)
                        .onTapGesture {
                            selectedBelief = belief
                        }
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var debatesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(debateBeliefs) { belief in
                    MacDebateRow(belief: belief)
                        .onTapGesture {
                            selectedBelief = belief
                        }
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(topEvidence) { item in
                    MacLeaderboardRow(entry: item)
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var filteredSharedBeliefs: [SharedBelief] {
        if searchText.isEmpty {
            return communityStore.sharedBeliefs
        }
        return communityStore.sharedBeliefs.filter {
            $0.beliefText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var debateBeliefs: [SharedBelief] {
        communityStore.sharedBeliefs
            .filter { abs($0.score - 50) < 20 }
            .sorted { abs($0.score - 50) > abs($1.score - 50) }
    }

    private var topEvidence: [LeaderboardEntry] {
        communityStore.sharedBeliefs
            .sorted { $0.supportingCount + $0.contradictingCount > $1.supportingCount + $1.contradictingCount }
            .prefix(10)
            .enumerated()
            .map { LeaderboardEntry(rank: $0.offset + 1, belief: $0.element) }
    }

    @ViewBuilder
    private var detailView: some View {
        if let belief = selectedBelief {
            MacBeliefDebateView(belief: belief)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.spacingL) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.textSecondary.opacity(0.3))
                Text("Select a belief to view its debate thread")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Supporting Types

struct LeaderboardEntry: Identifiable {
    var id: Int { rank }
    let rank: Int
    let belief: SharedBelief
}

// MARK: - MacCommunityBeliefRow

struct MacCommunityBeliefRow: View {
    let belief: SharedBelief
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                if belief.isCore {
                    Text("CORE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.accentGold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Theme.accentGold.opacity(0.15))
                        .cornerRadius(3)
                }
                Spacer()
                Text("\(Int(belief.score))")
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.scoreColor(for: belief.score))
            }

            Text(belief.beliefText)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3)

            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accentGreen)
                    Text("\(belief.supportingCount)")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
                HStack(spacing: 2) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accentRed)
                    Text("\(belief.contradictingCount)")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text(ShareCodeGenerator.formatDisplayCode(belief.shareCode))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(isSelected ? Theme.surfaceElevated : Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.accentGold.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - MacDebateRow

struct MacDebateRow: View {
    let belief: SharedBelief

    private var debateIntensity: Int {
        belief.supportingCount + belief.contradictingCount
    }

    private var debateLabel: String {
        if debateIntensity >= 10 { return "Hot" }
        else if debateIntensity >= 5 { return "Active" }
        else { return "New" }
    }

    private var debateColor: Color {
        if debateIntensity >= 10 { return Theme.accentRed }
        else if debateIntensity >= 5 { return Theme.accentGold }
        else { return Theme.accentBlue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text(debateLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(debateColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(debateColor.opacity(0.15))
                    .cornerRadius(4)

                Text("\(debateIntensity) responses")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Text(belief.sharedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            Text(belief.beliefText)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3)

            HStack {
                // Supporting side
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(belief.supportingCount) for")
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                    ProgressBarView(value: belief.score, color: Theme.accentGreen)
                }
                .frame(maxWidth: .infinity)

                Text("\(Int(belief.score))%")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.scoreColor(for: belief.score))
                    .frame(width: 40)

                // Contradicting side
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(belief.contradictingCount) against")
                        .font(.caption)
                        .foregroundColor(Theme.accentRed)
                    ProgressBarView(value: 100 - belief.score, color: Theme.accentRed)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - MacLeaderboardRow

struct MacLeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Text("#\(entry.rank)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.belief.beliefText)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Theme.spacingS) {
                    Text("\(entry.belief.supportingCount + entry.belief.contradictingCount) pieces")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(entry.belief.score))% confidence")
                        .font(.caption2)
                        .foregroundColor(Theme.scoreColor(for: entry.belief.score))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Theme.accentGold
        case 2: return Theme.accentBlue
        case 3: return Theme.accentRed
        default: return Theme.textSecondary
        }
    }
}

// MARK: - ProgressBarView

struct ProgressBarView: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.border)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(value / 100))
            }
        }
        .frame(height: 4)
    }
}

// MARK: - MacBeliefDebateView

struct MacBeliefDebateView: View {
    let belief: SharedBelief
    @State private var isExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                headerSection
                scoreBreakdownSection
                debateThreadSection
            }
            .padding(Theme.screenMargin)
        }
        .background(Theme.background)
        .navigationTitle("Debate Thread")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            if belief.isCore {
                Text("CORE BELIEF")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.accentGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGold.opacity(0.15))
                    .cornerRadius(4)
            }
            Text(belief.beliefText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            HStack {
                Text(ShareCodeGenerator.formatDisplayCode(belief.shareCode))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                Text("·")
                    .foregroundColor(Theme.textSecondary)
                Text("Shared \(belief.sharedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var scoreBreakdownSection: some View {
        HStack(spacing: Theme.spacingL) {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Confidence Score")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text("\(Int(belief.score))%")
                    .font(.system(size: 36, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.scoreColor(for: belief.score))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Theme.spacingM) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accentGreen)
                    Text("\(belief.supportingCount) supporting")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                }
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.accentRed)
                    Text("\(belief.contradictingCount) contradicting")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var debateThreadSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Debate Thread")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("This belief is \(debateIntensity)ly debated in the community.")
                .font(.callout)
                .foregroundColor(Theme.textSecondary)

            // Show sample debate positions
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                DebatePositionRow(
                    position: "Supporting",
                    count: belief.supportingCount,
                    color: Theme.accentGreen,
                    icon: "checkmark.circle.fill"
                )
                DebatePositionRow(
                    position: "Contradicting",
                    count: belief.contradictingCount,
                    color: Theme.accentRed,
                    icon: "xmark.circle.fill"
                )
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var debateIntensity: String {
        let total = belief.supportingCount + belief.contradictingCount
        if total >= 10 { return "highly" }
        else if total >= 5 { return "moderately" }
        else { return "mildly" }
    }
}

struct DebatePositionRow: View {
    let position: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(position)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(Theme.spacingS)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - MacCommunityPostSheet

struct MacCommunityPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedBelief: Belief?
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Select a belief to share anonymously with the community.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    if databaseService.allBeliefs.isEmpty {
                        VStack(spacing: Theme.spacingM) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.textSecondary.opacity(0.5))
                            Text("No beliefs yet")
                                .font(.headline)
                                .foregroundColor(Theme.textSecondary)
                            Text("Create a belief first, then share it here.")
                                .font(.callout)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingXL)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.spacingS) {
                                ForEach(databaseService.allBeliefs.filter { !$0.isArchived }) { belief in
                                    Button {
                                        selectedBelief = belief
                                    } label: {
                                        HStack {
                                            ScoreBadge(score: belief.score)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(belief.text)
                                                    .font(.subheadline)
                                                    .foregroundColor(Theme.textPrimary)
                                                    .lineLimit(2)
                                                if belief.isCore {
                                                    Text("CORE")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(Theme.accentGold)
                                                }
                                            }
                                            Spacer()
                                            if selectedBelief?.id == belief.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accentGold)
                                            }
                                        }
                                        .padding(Theme.spacingS)
                                        .background(selectedBelief?.id == belief.id ? Theme.accentGold.opacity(0.1) : Theme.surface)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedBelief?.id == belief.id ? Theme.accentGold : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Spacer()

                    if showingSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accentGreen)
                            Text("Belief shared successfully!")
                                .font(.subheadline)
                                .foregroundColor(Theme.accentGreen)
                        }
                        .padding(Theme.spacingM)
                        .frame(maxWidth: .infinity)
                        .background(Theme.accentGreen.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Share Belief")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        shareBelief()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedBelief == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func shareBelief() {
        guard let belief = selectedBelief else { return }
        CommunityStore.shared.addSharedBelief(belief)
        withAnimation {
            showingSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    MacCommunityView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
