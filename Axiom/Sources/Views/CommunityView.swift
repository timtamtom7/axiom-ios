import SwiftUI

/// Community belief audit browser — view anonymously shared beliefs
struct CommunityView: View {
    @StateObject private var communityStore = CommunityStore.shared
    @State private var searchText = ""
    @State private var selectedFilter: BeliefFilter = .all
    @State private var showingShareCodeSheet = false
    @State private var shareCode = ""
    @State private var isLoading = true
    @State private var loadError: String?

    enum BeliefFilter: String, CaseIterable {
        case all = "Feed"
        case circles = "Circles"
        case partners = "Partners"
        case core = "Core"
        case supported = "Supported"
        case challenged = "Challenged"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter tabs
                    filterBar

                    // Search
                    searchBar

                    // Community beliefs content
                    contentView
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingShareCodeSheet = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingShareCodeSheet) {
                CommunityShareCodeSheet()
            }
            .onAppear {
                loadCommunity()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedFilter {
        case .circles:
            SupportCirclesView()
        case .partners:
            AccountabilityPartnersView()
        default:
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(message: error)
            } else if filteredBeliefs.isEmpty {
                emptyView
            } else {
                communityScrollView
            }
        }
    }

    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonCommunityCard()
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "person.3",
                title: "No Shared Beliefs Yet",
                subtitle: "Share yours to help others on their belief journey.",
                actionTitle: "Share a Belief"
            ) {
                showingShareCodeSheet = true
            }
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            ErrorView(message: message) {
                loadCommunity()
            }
            Spacer()
        }
    }

    private var communityScrollView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(filteredBeliefs) { belief in
                    CommunityBeliefCard(belief: belief)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            }
            .padding(Theme.screenMargin)
            .animation(.spring(response: 0.3), value: filteredBeliefs.count)
        }
    }

    private func loadCommunity() {
        isLoading = true
        loadError = nil
        // Simulate network load for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(BeliefFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundColor(selectedFilter == filter ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(selectedFilter == filter ? Theme.accentGold.opacity(0.15) : Theme.surface)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, Theme.spacingS)
        }
        .background(Theme.surfaceElevated)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)
            TextField("Search community beliefs...", text: $searchText)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .padding(Theme.screenMargin)
    }

    private var filteredBeliefs: [SharedBelief] {
        var beliefs = communityStore.sharedBeliefs

        // Apply filter
        switch selectedFilter {
        case .all: break
        case .circles, .partners: beliefs = []
        case .core: beliefs = beliefs.filter { $0.isCore }
        case .supported: beliefs = beliefs.filter { $0.score >= 60 }
        case .challenged: beliefs = beliefs.filter { $0.score < 50 }
        }

        // Apply search
        if !searchText.isEmpty {
            beliefs = beliefs.filter {
                $0.beliefText.localizedCaseInsensitiveContains(searchText)
            }
        }

        return beliefs
    }
}

// MARK: - CommunityBeliefCard

struct CommunityBeliefCard: View {
    let belief: SharedBelief
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header
            HStack {
                if belief.isCore {
                    Text("CORE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.accentGold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.accentGold.opacity(0.15))
                        .cornerRadius(3)
                }

                Spacer()

                Text("\(Int(belief.score))")
                    .font(.system(size: 18, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }

            Text(belief.beliefText)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(isExpanded ? nil : 3)

            // Footer
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
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)

                Text(belief.sharedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            // Expand/collapse
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                Text(isExpanded ? "Show less" : "Show more")
                    .font(.caption)
                    .foregroundColor(Theme.accentBlue)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var scoreColor: Color {
        if belief.score < 40 { return Theme.accentRed }
        else if belief.score < 70 { return Theme.accentGold }
        else { return Theme.accentGreen }
    }
}

struct CommunityShareCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shareCodeInput = ""
    @State private var errorMessage: String?
    @State private var foundBelief: SharedBelief?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Enter a community share code")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    TextField("e.g. K9X2M1", text: $shareCodeInput)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .textFieldStyle(.plain)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .autocapitalization(.allCharacters)
                        .onChange(of: shareCodeInput) { _, newValue in
                            shareCodeInput = String(newValue.uppercased().prefix(6))
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.accentRed)
                    }

                    if let belief = foundBelief {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Found Belief:")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)

                            CommunityBeliefCard(belief: belief)
                        }
                    }

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Join Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Look Up") {
                        lookUpCode()
                    }
                    .disabled(shareCodeInput.count < 6)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func lookUpCode() {
        if let result = SharedBelief.parse(shareCode: shareCodeInput) {
            foundBelief = SharedBelief(
                id: UUID(),
                beliefText: result.text,
                isCore: result.isCore,
                score: Double(result.score),
                supportingCount: 0,
                contradictingCount: 0,
                sharedAt: Date(),
                shareCode: shareCodeInput
            )
            errorMessage = nil
        } else {
            errorMessage = "Code not found in community. Try: K9X2M1 (sample)"
            foundBelief = CommunityStore.shared.sharedBeliefs.first { $0.shareCode == shareCodeInput.uppercased() }
        }
    }
}
