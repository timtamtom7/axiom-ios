import SwiftUI

struct BeliefListView: View {
    @StateObject private var viewModel = BeliefListViewModel()
    @State private var showingAddBelief = false
    @State private var showingArchived = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.filteredBeliefs.isEmpty {
                    EmptyStateView(
                        icon: "brain",
                        title: "No Beliefs Yet",
                        subtitle: "Start by recording a belief you hold about yourself.",
                        actionTitle: "Add First Belief"
                    ) {
                        showingAddBelief = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            // Check-ins Due banner
                            if !viewModel.beliefsDueForCheckIn.isEmpty {
                                checkInsDueBanner
                            }
                            ForEach(viewModel.filteredBeliefs) { belief in
                                NavigationLink(destination: BeliefDetailView(belief: belief)) {
                                    BeliefCard(
                                        belief: belief,
                                        connectionCount: viewModel.connectionCount(for: belief.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.screenMargin)
                        .padding(.top, Theme.spacingM)
                    }
                }
            }
            .navigationTitle("Axiom")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBelief = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    if viewModel.archivedBeliefs.count > 0 {
                        Button {
                            showingArchived = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "archivebox")
                                Text("Obituaries (\(viewModel.archivedBeliefs.count))")
                            }
                            .font(.subheadline)
                        }
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
