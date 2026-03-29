import SwiftUI
import Charts

struct BeliefTrajectoryView: View {
    @ObservedObject var databaseService = DatabaseService.shared
    let belief: Belief

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Belief Journey")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if belief.scoreHistory.isEmpty {
                emptyChartPlaceholder
            } else {
                trajectoryChart
            }

            statsRow
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(Theme.textSecondary.opacity(0.4))
            Text("No history yet")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            Text("Track your belief over time by adding evidence")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var trajectoryChart: some View {
        Chart {
            ForEach(belief.scoreHistory) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Score", entry.score)
                )
                .foregroundStyle(Theme.accentPurple)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Score", entry.score)
                )
                .foregroundStyle(Theme.accentPurple)
                .symbolSize(30)
            }

            // 50% reference line
            RuleMark(y: .value("Neutral", 50))
                .foregroundStyle(Theme.textSecondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("50%")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
        }
        .frame(height: 200)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
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
    }

    private var statsRow: some View {
        HStack(spacing: Theme.spacingL) {
            statItem(
                title: "Current",
                value: "\(Int(belief.score))%",
                color: Theme.scoreColor(for: belief.score)
            )

            if !belief.scoreHistory.isEmpty {
                let change = belief.score - (belief.scoreHistory.first?.score ?? belief.score)
                statItem(
                    title: "Change",
                    value: "\(change >= 0 ? "+" : "")\(Int(change))%",
                    color: change >= 0 ? Theme.accentGreen : Theme.accentRed
                )

                let avgScore = belief.scoreHistory.map(\.score).reduce(0, +) / Double(belief.scoreHistory.count)
                statItem(
                    title: "Average",
                    value: "\(Int(avgScore))%",
                    color: Theme.accentBlue
                )

                statItem(
                    title: "Data Points",
                    value: "\(belief.scoreHistory.count)",
                    color: Theme.textSecondary
                )
            }
        }
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    BeliefTrajectoryView(
        belief: Belief(
            text: "I am capable of learning anything",
            scoreHistory: [
                ScoreEntry(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, score: 65),
                ScoreEntry(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, score: 62),
                ScoreEntry(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, score: 70),
                ScoreEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, score: 68),
                ScoreEntry(date: Date(), score: 75)
            ]
        )
    )
    .frame(width: 400)
    .preferredColorScheme(.dark)
}
