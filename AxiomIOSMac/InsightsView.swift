import SwiftUI

struct InsightsView: View {
    @StateObject private var dataService = DataService.shared
    @StateObject private var beliefService = AIBeliefService.shared
    @StateObject private var patternService = PatternDetectionService.shared
    @State private var selectedTimeRange = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                Picker("", selection: $selectedTimeRange) {
                    Text("Week").tag(0)
                    Text("Month").tag(1)
                    Text("All Time").tag(2)
                }
                .pickerStyle(.segmented)

                // AI Analysis Card
                AIAnalysisCard(beliefs: dataService.beliefs, beliefService: beliefService)

                // Belief Trajectory
                BeliefTrajectoryCard(beliefs: dataService.beliefs)

                // Weekly Synthesis
                WeeklySynthesisCard(beliefs: dataService.beliefs)

                // Thought Patterns
                ThoughtPatternsCard(patternService: patternService, beliefs: dataService.beliefs)

                // Cognitive Distortions
                CognitiveDistortionsCard(beliefs: dataService.beliefs, beliefService: beliefService)
            }
            .padding(20)
        }
        .background(Theme.surface)
    }
}

struct AIAnalysisCard: View {
    let beliefs: [Belief]
    @ObservedObject var beliefService: AIBeliefService
    @State private var isExpanded = false
    @State private var insights: [AIInsight] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("AI Belief Analysis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if !insights.isEmpty {
                ForEach(insights.prefix(3)) { insight in
                    InsightRow(icon: insight.icon, color: insight.color, text: insight.text)
                }
            } else if beliefs.isEmpty {
                Text("Add beliefs to receive AI analysis")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Based on your evidence patterns:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    ForEach(insights) { insight in
                        InsightRow(icon: insight.icon, color: insight.color, text: insight.text)
                    }

                    Button {
                        refreshInsights()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Analysis")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .onAppear { refreshInsights() }
    }

    private func refreshInsights() {
        insights = generateInsights(from: beliefs)
    }

    private func generateInsights(from beliefs: [Belief]) -> [AIInsight] {
        var result: [AIInsight] = []

        for belief in beliefs {
            let distortions = beliefService.detectDistortions(in: belief.text)
            if let first = distortions.first {
                result.append(AIInsight(
                    icon: "exclamationmark.triangle.fill",
                    color: Theme.accentGold,
                    text: "\"\(belief.text.prefix(40))...\" shows: \(first.type.rawValue)"
                ))
            }
        }

        let sentiment = beliefs.prefix(3).map { beliefService.analyzeSentiment(of: $0.text) }
        let avgScore = sentiment.isEmpty ? 0 : sentiment.map(\.score).reduce(0, +) / Double(sentiment.count)
        if avgScore < -0.2 {
            result.append(AIInsight(
                icon: "heart.fill",
                color: Theme.accentRed,
                text: "Your recent beliefs lean negative (\(String(format: "%.0f", avgScore * 100))% score). Consider exploring more balanced perspectives."
            ))
        } else if avgScore > 0.2 {
            result.append(AIInsight(
                icon: "checkmark.seal.fill",
                color: Theme.accentGreen,
                text: "Your recent beliefs show positive emotional tone — well done!"
            ))
        }

        let patterns = beliefService.detectPatternsAcrossBeliefs(beliefs)
        if let topPattern = patterns.first {
            result.append(AIInsight(
                icon: "waveform.path.ecg",
                color: Theme.accentBlue,
                text: topPattern.title + ": " + topPattern.description.prefix(60) + "..."
            ))
        }

        return result
    }
}

struct AIInsight: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let text: String
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Theme.navy.opacity(0.85))
        }
    }
}

struct BeliefTrajectoryCard: View {
    let beliefs: [Belief]

    var sortedBeliefs: [Belief] {
        beliefs.sorted { $0.score > $1.score }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("Belief Trajectory")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
            }

            ForEach(sortedBeliefs.prefix(3)) { belief in
                HStack(spacing: 10) {
                    Text(belief.text)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.navy)
                        .lineLimit(1)
                        .frame(maxWidth: 180, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.surface)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(scoreColor(for: belief.score))
                                .frame(width: geo.size.width * (belief.score / 100), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(Int(belief.score))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(scoreColor(for: belief.score))
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    func scoreColor(for score: Double) -> Color {
        switch ScoreLevel(score: score) {
        case .low: return Theme.accentRed
        case .medium: return Theme.accentGold
        case .high: return Theme.accentGreen
        }
    }
}

struct WeeklySynthesisCard: View {
    let beliefs: [Belief]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("Weekly Synthesis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Text("Week 13")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                SynthesisRow(label: "Beliefs tracked", value: "\(beliefs.count)")
                SynthesisRow(label: "Evidence added", value: "\(beliefs.flatMap { $0.evidenceItems }.count)")
                SynthesisRow(label: "Core beliefs updated", value: "\(beliefs.filter { $0.isCore }.count)")
                SynthesisRow(label: "Avg. belief strength", value: "\(Int(beliefs.map { $0.score }.reduce(0, +) / Double(max(1, beliefs.count))))")
            }

            Divider()

            Text("This week you added evidence to your belief about self-worth. Your perspective shifted toward more balanced thinking.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct SynthesisRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.navy)
        }
    }
}

struct ThoughtPatternsCard: View {
    @ObservedObject var patternService: PatternDetectionService
    let beliefs: [Belief]
    @State private var patterns: [PatternDetectionService.Pattern] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("Thought Patterns Detected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
            }

            if !patterns.isEmpty {
                ForEach(patterns.prefix(4)) { pattern in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: pattern.color) ?? Theme.accentGold)
                            .frame(width: 8, height: 8)
                        Text(pattern.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.navy)
                        Spacer()
                        Image(systemName: pattern.type.icon)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Add more beliefs to detect patterns")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .onAppear { loadPatterns() }
    }

    private func loadPatterns() {
        patterns = patternService.analyzeAllPatterns(in: beliefs)
    }
}

struct CognitiveDistortionsCard: View {
    let beliefs: [Belief]
    @ObservedObject var beliefService: AIBeliefService
    @State private var allDistortions: [DetectedDistortion] = []
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("Cognitive Distortions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Text("\(allDistortions.count) detected")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            let grouped = Dictionary(grouping: allDistortions, by: \.type)
            ForEach(Array(grouped.keys.prefix(3)), id: \.self) { type in
                if let items = grouped[type], let first = items.first {
                    HStack(spacing: 10) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: first.severity.color) ?? Theme.accentGold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.navy)
                            Text(first.socraticChallenge)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }

            if allDistortions.isEmpty {
                Text("No distortions detected — keep adding beliefs!")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .onAppear { detectDistortions() }
    }

    private func detectDistortions() {
        var all: [DetectedDistortion] = []
        for belief in beliefs {
            all.append(contentsOf: beliefService.detectDistortions(in: belief.text))
        }
        allDistortions = all
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct ThoughtPattern: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
    let severity: Severity

    enum Severity {
        case mild, moderate, high
    }

    var severityColor: Color {
        switch severity {
        case .mild: return Theme.accentGreen
        case .moderate: return Theme.accentGold
        case .high: return Theme.accentRed
        }
    }

    static func samples() -> [ThoughtPattern] {
        [
            ThoughtPattern(name: "All-or-Nothing Thinking", frequency: "3x this week", severity: .moderate),
            ThoughtPattern(name: "Catastrophizing", frequency: "1x this week", severity: .mild),
            ThoughtPattern(name: "Mind Reading", frequency: "2x this week", severity: .high)
        ]
    }
}
