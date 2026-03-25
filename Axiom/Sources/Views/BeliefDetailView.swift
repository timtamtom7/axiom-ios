import SwiftUI

struct BeliefDetailView: View {
    @StateObject private var viewModel: BeliefDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false

    init(belief: Belief) {
        _viewModel = StateObject(wrappedValue: BeliefDetailViewModel(belief: belief))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    // Header
                    headerSection

                    // Score
                    scoreSection

                    // Stress Test CTA
                    stressTestSection

                    // Supporting Evidence
                    evidenceSection(
                        title: "Supporting Evidence",
                        icon: "checkmark.circle.fill",
                        color: Theme.accentGreen,
                        items: viewModel.supportingEvidence
                    )

                    // Contradicting Evidence
                    evidenceSection(
                        title: "Contradicting Evidence",
                        icon: "xmark.circle.fill",
                        color: Theme.accentRed,
                        items: viewModel.contradictingEvidence
                    )

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, Theme.screenMargin)
            }
        }
        .navigationTitle("Belief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Belief", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showingAddEvidence) {
            AddEvidenceView(beliefId: viewModel.belief.id) { text, type in
                viewModel.addEvidence(text: text, type: type)
            }
        }
        .sheet(isPresented: $viewModel.showingStressTest) {
            AIStressTestView(belief: viewModel.belief)
        }
        .alert("Delete Belief?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteBelief()
                dismiss()
            }
        } message: {
            Text("This will permanently delete this belief and all its evidence.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(viewModel.belief.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("Created \(viewModel.belief.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, Theme.spacingM)
    }

    private var scoreSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Evidence Score")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Text(scoreDescription)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            ScoreBadge(score: viewModel.belief.score)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var scoreDescription: String {
        let score = viewModel.belief.score
        if score < 40 {
            return "Evidence leans against this belief"
        } else if score < 70 {
            return "Evidence is mixed"
        } else {
            return "Evidence supports this belief"
        }
    }

    private var stressTestSection: some View {
        Button {
            viewModel.showingStressTest = true
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.headline)
                Text("AI Stress Test")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(Theme.accentBlue)
            .padding(Theme.spacingM)
            .background(Theme.accentBlue.opacity(0.15))
            .cornerRadius(12)
        }
    }

    private func evidenceSection(title: String, icon: String, color: Color, items: [Evidence]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("(\(items.count))")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button {
                    viewModel.showingAddEvidence = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                }
            }

            if items.isEmpty {
                Text("No evidence yet")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(items) { item in
                    EvidenceRow(evidence: item) {
                        viewModel.deleteEvidence(item)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        BeliefDetailView(belief: .preview)
    }
    .environmentObject(DatabaseService.shared)
    .preferredColorScheme(.dark)
}
