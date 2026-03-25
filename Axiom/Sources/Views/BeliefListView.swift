import SwiftUI

struct BeliefListView: View {
    @StateObject private var viewModel = BeliefListViewModel()
    @State private var showingAddBelief = false

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
                            ForEach(viewModel.filteredBeliefs) { belief in
                                NavigationLink(destination: BeliefDetailView(belief: belief)) {
                                    BeliefCard(belief: belief)
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
            }
            .searchable(text: $viewModel.searchText, prompt: "Search beliefs")
            .sheet(isPresented: $showingAddBelief) {
                AddBeliefView { text in
                    viewModel.addBelief(text: text)
                }
            }
        }
    }
}

#Preview {
    BeliefListView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
