import SwiftUI
import Charts

// MARK: - Insights Dashboard View

struct InsightsDashboardView: View {
    @ObservedObject private var databaseService = DatabaseService.shared
    @ObservedObject private var streakService = StreakService.shared
    @StateObject private var aiService = AIBeliefService.shared
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedPattern: BeliefPattern?
    @State private var showingPatternDetail = false

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    streakCard
                    timeRangePicker
                    synthesisCard
                    beliefTrajectoryOverview
                    patternsCard
                    weeklyHeatMap
                    distortionSummaryCard
                }
                .padding(.horizontal, Theme.screenMargin)
                .padding(.vertical, Theme.spacingM)
            }
            .background(Theme.background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingXL) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streakService.currentStreak)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accentGold)
                        Text("days")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streakService.bestStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("days")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            Text(streakService.streakMessage)
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.spacingM)
        .background(
            LinearGradient(
                colors: [Theme.accentGold.opacity(0.15), Theme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Theme.cornerRadiusL)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Synthesis Card

    private var synthesisCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.accentPurple)
                Text("Weekly Synthesis")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            Text(synthesisText)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.border)

            HStack(spacing: Theme.spacingL) {
                synthesisStat(label: "Beliefs", value: "\(databaseService.allBeliefs.count)", color: Theme.accentBlue)
                synthesisStat(label: "Evidence", value: "\(totalEvidenceCount)", color: Theme.accentGreen)
                synthesisStat(label: "Avg Score", value: "\(Int(averageScore))%", color: Theme.scoreColor(for: averageScore))
                synthesisStat(label: "Days Active", value: "\(streakService.totalActiveDays)", color: Theme.accentGold)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private func synthesisStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var synthesisText: String {
        let beliefs = databaseService.allBeliefs
        guard !beliefs.isEmpty else {
            return "Start adding beliefs to receive your personalized weekly synthesis."
        }

        let lowScore = beliefs.filter { $0.score < 40 }.count
        let highScore = beliefs.filter { $0.score >= 70 }.count
        let recentNew = beliefs.filter {
            Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 0 < 7
        }.count

        var synthesis = ""

        if recentNew > 0 {
            synthesis += "This week you added \(recentNew) new belief\(recentNew == 1 ? "" : "s"). "
        }

        if lowScore > 0 {
            synthesis += "\(lowScore) belief\(lowScore == 1 ? " needs" : "s need") more evidence. "
        }

        if highScore > 0 {
            synthesis += "\(highScore) belief\(highScore == 1 ? " is" : "s are") strongly supported. "
        }

        let totalEvidence = beliefs.map(\.evidenceItems.count).reduce(0, +)
        if totalEvidence > 0 {
            let avgEvidence = Double(totalEvidence) / Double(beliefs.count)
            if avgEvidence < 2 {
                synthesis += "Consider adding more perspectives to your beliefs for richer analysis."
            } else {
                synthesis += "Your belief portfolio is actively evolving. Keep questioning."
            }
        }

        if synthesis.isEmpty {
            synthesis = "Your belief audit is progressing well. Continue examining your beliefs from multiple angles."
        }

        return synthesis
    }

    // MARK: - Belief Trajectory Overview

    private var beliefTrajectoryOverview: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.accentBlue)
                Text("Belief Trajectories")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            if beliefsWithHistory.isEmpty {
                Text("Add evidence over time to see trajectory charts.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.spacingL)
            } else {
                trajectoryChart
                trajectoryLegend
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private var beliefsWithHistory: [Belief] {
        databaseService.allBeliefs.filter { $0.scoreHistory.count >= 2 }
    }

    private var trajectoryChart: some View {
        Chart {
            ForEach(beliefsWithHistory.prefix(5)) { belief in
                ForEach(belief.scoreHistory.sorted { $0.date < $1.date }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Score", entry.score),
                        series: .value("Belief", belief.text.prefix(20).description)
                    )
                    .foregroundStyle(by: .value("Belief", belief.text.prefix(20).description))
                    .interpolationMethod(.catmullRom)
                }
            }

            RuleMark(y: .value("Neutral", 50))
                .foregroundStyle(Theme.textSecondary.opacity(0.2))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 220)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Theme.border)
                AxisValueLabel()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Theme.border)
                AxisValueLabel()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .chartYScale(domain: 0...100)
        .chartForegroundStyleScale([
            beliefsWithHistory[0].text.prefix(20).description: Theme.accentPurple,
            beliefsWithHistory[safe: 1]?.text.prefix(20).description ?? "": Theme.accentBlue,
            beliefsWithHistory[safe: 2]?.text.prefix(20).description ?? "": Theme.accentGreen,
            beliefsWithHistory[safe: 3]?.text.prefix(20).description ?? "": Theme.accentGold,
            beliefsWithHistory[safe: 4]?.text.prefix(20).description ?? "": Theme.accentRed
        ])
    }

    private var trajectoryLegend: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(beliefsWithHistory.prefix(5)) { belief in
                HStack(spacing: Theme.spacingS) {
                    Circle()
                        .fill(legendColor(for: belief))
                        .frame(width: 8, height: 8)
                    Text(belief.text.prefix(30))
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func legendColor(for belief: Belief) -> Color {
        let index = beliefsWithHistory.firstIndex(of: belief) ?? 0
        switch index {
        case 0: return Theme.accentPurple
        case 1: return Theme.accentBlue
        case 2: return Theme.accentGreen
        case 3: return Theme.accentGold
        default: return Theme.accentRed
        }
    }

    // MARK: - Patterns Card

    private var patternsCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.accentPurple)
                Text("Detected Patterns")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            let patterns = aiService.detectPatternsAcrossBeliefs(databaseService.allBeliefs)

            if patterns.isEmpty {
                Text("Patterns will emerge as you add more beliefs and evidence.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, Theme.spacingS)
            } else {
                ForEach(patterns.prefix(5)) { pattern in
                    PatternRow(pattern: pattern) {
                        selectedPattern = pattern
                        showingPatternDetail = true
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
        .sheet(isPresented: $showingPatternDetail) {
            if let pattern = selectedPattern {
                PatternDetailSheet(pattern: pattern)
            }
        }
    }

    // MARK: - Weekly Heat Map

    private var weeklyHeatMap: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.accentGreen)
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: Theme.spacingS) {
                ForEach(streakService.weeklyHeatMapData()) { day in
                    VStack(spacing: 4) {
                        Text(day.dayLetter)
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatMapColor(for: day))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if day.hasActivity {
                                    Text("\(Calendar.current.component(.day, from: day.date))")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(Calendar.current.component(.day, from: day.date))")
                                        .font(.caption2)
                                        .foregroundColor(Theme.textSecondary.opacity(0.4))
                                }
                            }
                    }
                }
            }

            HStack(spacing: Theme.spacingM) {
                heatMapLegend(color: Theme.textSecondary.opacity(0.2), label: "No activity")
                heatMapLegend(color: Theme.accentGreen.opacity(0.3), label: "Low")
                heatMapLegend(color: Theme.accentGreen.opacity(0.6), label: "Medium")
                heatMapLegend(color: Theme.accentGreen, label: "High")
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private func heatMapColor(for day: DayActivity) -> Color {
        switch day.activityLevel {
        case 0: return Theme.textSecondary.opacity(0.15)
        case 1: return Theme.accentGreen.opacity(0.3)
        case 2: return Theme.accentGreen.opacity(0.6)
        default: return Theme.accentGreen
        }
    }

    private func heatMapLegend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
    }

    // MARK: - Distortion Summary Card

    private var distortionSummaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(Theme.accentRed)
                Text("Thinking Patterns")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            let allDistortions = databaseService.allBeliefs.flatMap { aiService.detectDistortions(in: $0.text) }
            let topDistortions = Dictionary(grouping: allDistortions, by: { $0.type })
                .sorted { $0.value.count > $1.value.count }
                .prefix(4)

            if topDistortions.isEmpty {
                Text("Add beliefs to see cognitive distortion analysis.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, Theme.spacingS)
            } else {
                ForEach(Array(topDistortions), id: \.key) { type, instances in
                    DistortionBar(type: type, count: instances.count, total: allDistortions.count)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    // MARK: - Computed Stats

    private var totalEvidenceCount: Int {
        databaseService.allBeliefs.map(\.evidenceItems.count).reduce(0, +)
    }

    private var averageScore: Double {
        let beliefs = databaseService.allBeliefs
        guard !beliefs.isEmpty else { return 50 }
        return beliefs.map(\.score).reduce(0, +) / Double(beliefs.count)
    }
}

// MARK: - Pattern Row

struct PatternRow: View {
    let pattern: BeliefPattern
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacingM) {
                Image(systemName: pattern.icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: pattern.color))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.textPrimary)
                    Text(pattern.description)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.spacingS)
            .background(Theme.surfaceElevated)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pattern Detail Sheet

struct PatternDetailSheet: View {
    let pattern: BeliefPattern
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    HStack {
                        Image(systemName: pattern.icon)
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: pattern.color))
                        Spacer()
                    }
                    .padding(.horizontal)

                    Text(pattern.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)

                    Text(pattern.description)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)

                    Divider()
                        .background(Theme.border)

                    Text("Affected Beliefs")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    let beliefs = DatabaseService.shared.allBeliefs.filter { pattern.affectedBeliefIds.contains($0.id) }
                    ForEach(beliefs) { belief in
                        NavigationLink(destination: BeliefDetailView(belief: belief)) {
                            BeliefCard(belief: belief)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.spacingL)
            }
            .background(Theme.background)
            .navigationTitle("Pattern Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Distortion Bar

struct DistortionBar: View {
    let type: CognitiveDistortionType
    let count: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accentRed)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.textSecondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accentRed)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Safe Array Subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    InsightsDashboardView()
        .preferredColorScheme(.dark)
}
