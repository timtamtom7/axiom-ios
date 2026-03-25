import SwiftUI

struct AIStressTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIStressTestService()
    let belief: Belief

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if aiService.isLoading {
                    VStack(spacing: Theme.spacingM) {
                        ProgressView()
                            .tint(Theme.accentBlue)
                        Text("Generating challenges...")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else if aiService.challenges.isEmpty {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentBlue)

                        Text("AI Stress Test")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text("I'll challenge your belief with hard questions. No easy answers allowed.")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await aiService.generateChallenges(for: belief)
                            }
                        } label: {
                            Text("Start Challenge")
                                .font(.headline)
                                .foregroundColor(Theme.background)
                                .padding(.horizontal, Theme.spacingXL)
                                .padding(.vertical, Theme.spacingM)
                                .background(Theme.accentBlue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(Theme.screenMargin)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            Text("Challenge your belief:")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            ForEach($aiService.challenges) { $challenge in
                                ChallengeCard(challenge: $challenge)
                            }

                            // Analysis Summary
                            Button {
                                Task {
                                    let analysis = await aiService.getAnalysis(for: belief)
                                    await showAnalysis(analysis)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Request AI Analysis")
                                }
                                .font(.headline)
                                .foregroundColor(Theme.accentBlue)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.spacingM)
                                .background(Theme.accentBlue.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                        .padding(Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("Stress Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @MainActor
    private func showAnalysis(_ analysis: String) async {
        // Would show analysis in a sheet or alert
        print(analysis)
    }
}

struct ChallengeCard: View {
    @Binding var challenge: AIStressTestService.StressChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(Theme.accentBlue)
                Text("Challenge")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
            }

            Text(challenge.question)
                .font(.body)
                .foregroundColor(Theme.textPrimary)

            TextField("Your reflection...", text: $challenge.userResponse, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacingS)
                .background(Theme.surfaceElevated)
                .cornerRadius(8)
                .lineLimit(2...4)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    AIStressTestView(belief: .preview)
        .preferredColorScheme(.dark)
}
