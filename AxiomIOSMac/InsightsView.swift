import SwiftUI

struct InsightsView: View {
    @StateObject private var dataService = DataService.shared
    @StateObject private var beliefService = AIBeliefService.shared
    @StateObject private var patternService = PatternDetectionService.shared
    @State private var selectedTimeRange = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(0)
                    Text("Month").tag(1)
                    Text("All Time").tag(2)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Time range for insights")

                AIAnalysisCard(beliefs: dataService.beliefs, beliefService: beliefService)
                BeliefTrajectoryCard(beliefs: dataService.beliefs)
                WeeklySynthesisCard(beliefs: dataService.beliefs)
                ThoughtPatternsCard(patternService: patternService, beliefs: dataService.beliefs)
                CognitiveDistortionsCard(beliefs: dataService.beliefs, beliefService: beliefService)
            }
            .padding(20)
        }
    }
}

// MARK: - AI Analysis Card

struct AIAnalysisCard: View {
    let beliefs: [Belief]
    @ObservedObject var beliefService: AIBeliefService
    @State private var isExpanded = false
    @State private var insights: [AIInsight] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("AI Analysis")
                    .font(.headline)
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if insights.isEmpty {
                Text("Add beliefs to see AI insights")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
        .onAppear { generateInsights() }
    }

    private func generateInsights() {
        guard !beliefs.isEmpty else { return }
        isLoading = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            let analyses = beliefService.analyzeAllBeliefs(beliefs)
            insights = Array(analyses.values).prefix(5).map { analysis in
                let title: String
                let body: String
                if let first = analysis.distortions.first {
                    title = first.rawValue
                    body = first.gentleQuestion
                } else {
                    title = "Balanced View"
                    body = analysis.healthierAlternative
                }
                let type: InsightType = analysis.distortions.isEmpty ? .aiAnalysis : .beliefPattern
                return AIInsight(
                    id: analysis.id,
                    title: title,
                    body: body,
                    type: type
                )
            }
            isLoading = false
        }
    }
}

struct AIInsight: Identifiable, Equatable {
    let id: UUID
    let title: String
    let body: String
    let type: InsightType
}

struct InsightRow: View {
    let insight: AIInsight
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.title)
                .font(.subheadline.bold())
            Text(insight.body)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Belief Trajectory Card

struct BeliefTrajectoryCard: View {
    let beliefs: [Belief]
    @State private var selectedBelief: Belief?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Belief Trajectory")
                    .font(.headline)
                Spacer()
            }

            if beliefs.isEmpty {
                Text("No beliefs yet")
                    .foregroundColor(.secondary)
            } else {
                let sorted = beliefs.sorted { $0.createdAt < $1.createdAt }
                ForEach(sorted.prefix(5)) { belief in
                    Text(belief.text)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Synthesis Card

struct WeeklySynthesisCard: View {
    let beliefs: [Belief]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Weekly Synthesis")
                    .font(.headline)
                Spacer()
            }

            if beliefs.isEmpty {
                Text("No beliefs this week")
                    .foregroundColor(.secondary)
            } else {
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let recent = beliefs.filter { $0.createdAt >= weekAgo }
                Text("\(recent.count) belief(s) this week")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Thought Patterns Card

struct ThoughtPatternsCard: View {
    @ObservedObject var patternService: PatternDetectionService
    let beliefs: [Belief]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.orange)
                Text("Thought Patterns")
                    .font(.headline)
                Spacer()
            }

            let patterns = patternService.detectDistortionPatterns(from: beliefs)
            if patterns.isEmpty {
                Text("Not enough data to detect patterns")
                    .foregroundColor(.secondary)
            } else {
                ForEach(patterns.prefix(3)) { pattern in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.distortion.description)
                            .font(.subheadline.bold())
                        Text(pattern.distortion.gentleQuestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Cognitive Distortions Card

struct CognitiveDistortionsCard: View {
    let beliefs: [Belief]
    @ObservedObject var beliefService: AIBeliefService
    @State private var selectedBeliefIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(Theme.gold)
                Text("Cognitive Distortions")
                    .font(.headline)
                Spacer()
            }

            if beliefs.isEmpty {
                Text("Add beliefs to detect distortions")
                    .foregroundColor(.secondary)
            } else {
                let analysis = beliefService.analyzeAllBeliefs(beliefs)
                let analyses = Array(analysis.values)
                if !analyses.isEmpty {
                    ForEach(analyses.prefix(3)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.belief)
                                .font(.caption.bold())
                            Text(item.distortions.map { $0.description }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
}
