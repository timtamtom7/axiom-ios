import SwiftUI

struct BeliefListView: View {
    @StateObject private var viewModel = BeliefListViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingAddBelief = false
    @State private var showingArchived = false
    @State private var showingUpgrade = false
    @State private var isLoading = true
    @State private var cardAppearScale: CGFloat = 0.95

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if viewModel.filteredBeliefs.isEmpty {
                    emptyStateView
                } else {
                    beliefListContent
                }
            }
            .navigationTitle("Axiom")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticService.shared.selection()
                        if subscriptionService.canAddBelief {
                            showingAddBelief = true
                        } else {
                            showingUpgrade = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Add new belief")
                    .keyboardShortcut("n", modifiers: .command)
                }
                ToolbarItem(placement: .secondaryAction) {
                    if viewModel.archivedBeliefs.count > 0 {
                        Button {
                            HapticService.shared.selection()
                            showingArchived = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "archivebox")
                                Text("Obituaries (\(viewModel.archivedBeliefs.count))")
                            }
                            .font(.subheadline)
                        }
                        .accessibilityLabel("View archived beliefs")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search beliefs")
            .sheet(isPresented: $showingAddBelief) {
                AddBeliefView { text, isCore, rootCause in
                    viewModel.addBelief(text: text, isCore: isCore, rootCause: rootCause)
                }
            }
            .sheet(isPresented: $showingArchived) {
                ArchivedBeliefsView(beliefs: viewModel.archivedBeliefs)
            }
            .sheet(isPresented: $showingUpgrade) {
                SubscriptionView()
            }
            .onAppear {
                // Simulate initial load for skeleton demo
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonBeliefCard()
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.top, Theme.spacingM)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.spacingL) {
            BeliefNetworkIllustration(size: 180)
            EmptyStateView(
                icon: "brain",
                title: "No Beliefs Yet",
                subtitle: "Start by recording a belief you hold about yourself.",
                actionTitle: "Add First Belief"
            ) {
                showingAddBelief = true
            }
        }
    }

    private var beliefListContent: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                // Check-ins Due banner
                if !viewModel.beliefsDueForCheckIn.isEmpty {
                    checkInsDueBanner
                }
                ForEach(Array(viewModel.filteredBeliefs.enumerated()), id: \.element.id) { index, belief in
                    NavigationLink(destination: BeliefDetailView(belief: belief)) {
                        BeliefCard(
                            belief: belief,
                            connectionCount: viewModel.connectionCount(for: belief.id)
                        )
                        .scaleEffect(cardAppearScale)
                        .opacity(cardAppearScale == 1 ? 1 : 0)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3).delay(Double(index) * 0.05)) {
                            cardAppearScale = 1
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.top, Theme.spacingM)
        }
    }

    private var checkInsDueBanner: some View {
        VStack(spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(Theme.accentGold)
                Text("\(viewModel.beliefsDueForCheckIn.count) Check-In\(viewModel.beliefsDueForCheckIn.count > 1 ? "s" : "") Due")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accentGold)
                Spacer()
            }

            ForEach(viewModel.beliefsDueForCheckIn.prefix(3)) { belief in
                NavigationLink(destination: BeliefDetailView(belief: belief)) {
                    HStack {
                        ScoreBadge(score: belief.score)
                        Text(belief.text)
                            .font(.callout)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingS)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(8)
                }
            }

            if viewModel.beliefsDueForCheckIn.count > 3 {
                Text("+ \(viewModel.beliefsDueForCheckIn.count - 3) more")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.accentGold.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    BeliefListView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
