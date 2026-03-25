import SwiftUI

struct AIStressTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIStressTestService()
    let belief: Belief

    @State private var analysisResult = ""
    @State private var showingAnalysis = false
    @State private var analysisError: String?
    @State private var isLoadingAnalysis = false

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

                            ForEach(Array($aiService.challenges.enumerated()), id: \.element.id) { index, $challenge in
                                ChallengeCard(challenge: $challenge)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                                        removal: .opacity.combined(with: .move(edge: .leading))
                                    ))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.08), value: aiService.challenges.count)
                            }

                            // Analysis Summary
                            Button {
                                Task {
                                    isLoadingAnalysis = true
                                    analysisError = nil
                                    do {
                                        analysisResult = try await aiService.getAnalysis(for: belief)
                                        showingAnalysis = true
                                    } catch {
                                        analysisError = error.localizedDescription
                                        showingAnalysis = true
                                    }
                                    isLoadingAnalysis = false
                                }
                            } label: {
                                HStack {
                                    if isLoadingAnalysis {
                                        ProgressView()
                                            .tint(Theme.accentBlue)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "doc.text.magnifyingglass")
                                    }
                                    Text(isLoadingAnalysis ? "Analyzing..." : "Request AI Analysis")
                                }
                                .font(.headline)
                                .foregroundColor(Theme.accentBlue)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.spacingM)
                                .background(Theme.accentBlue.opacity(0.15))
                                .cornerRadius(12)
                            }
                            .disabled(isLoadingAnalysis)
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
        .sheet(isPresented: $showingAnalysis) {
            StressTestAnalysisSheet(
                analysis: analysisResult,
                belief: belief,
                error: analysisError
            )
        }
    }
}

struct StressTestAnalysisSheet: View {
    let analysis: String
    let belief: Belief
    let error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let error = error {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentRed)
                        Text("Analysis Failed")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        Text(error)
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, Theme.spacingXL)
                                .padding(.vertical, Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(Theme.screenMargin)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            Text(analysis)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .textSelection(.enabled)
                        }
                        .padding(Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
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
