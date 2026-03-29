import SwiftUI

struct InsightsView: View {
    @StateObject private var dataService = DataService.shared
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
                AIAnalysisCard()

                // Belief Trajectory
                BeliefTrajectoryCard(beliefs: dataService.beliefs)

                // Weekly Synthesis
                WeeklySynthesisCard(beliefs: dataService.beliefs)

                // Thought Patterns
                ThoughtPatternsCard()
            }
            .padding(20)
        }
        .background(Theme.surface)
    }
}

struct AIAnalysisCard: View {
    @State private var isExpanded = false

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

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Based on your evidence patterns:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    InsightRow(icon: "exclamationmark.triangle.fill", color: Theme.accentGold,
                               text: "Your belief \"I should put others first\" shows cognitive distortion: false dilemma")
                    InsightRow(icon: "arrow.triangle.swap", color: Theme.accentBlue,
                               text: "\"I'm not good enough\" correlates with negative self-talk triggered by criticism")
                    InsightRow(icon: "checkmark.seal.fill", color: Theme.accentGreen,
                               text: "Strongest belief: \"I am a good friend\" — well-supported by evidence")

                    Button {
                        // Refresh analysis
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
    }
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
    let patterns: [ThoughtPattern] = ThoughtPattern.samples()

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

            ForEach(patterns) { pattern in
                HStack(spacing: 10) {
                    Circle()
                        .fill(pattern.severityColor)
                        .frame(width: 8, height: 8)
                    Text(pattern.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.navy)
                    Spacer()
                    Text(pattern.frequency)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
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
