import SwiftUI

struct MacStreakView: View {
    @StateObject private var streakService = StreakService.shared
    @State private var showingReports = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                streakHeader
                streakStats
                weeklyHeatMap
                consistencyScore
                actionsSection
            }
            .padding(Theme.screenMargin)
        }
        .background(Theme.background)
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showingReports) {
            MacReportsView()
        }
    }

    // MARK: - Streak Header

    private var streakHeader: some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: streakIcon)
                    .font(.system(size: 48))
                    .foregroundColor(streakColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streakService.currentStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("day streak")
                        .font(.title3)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Text(streakService.streakMessage)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(streakColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var streakIcon: String {
        if streakService.currentStreak == 0 {
            return "flame"
        } else if streakService.currentStreak < 3 {
            return "flame"
        } else if streakService.currentStreak < 7 {
            return "flame.fill"
        } else {
            return "flame.fill"
        }
    }

    private var streakColor: Color {
        if streakService.currentStreak == 0 {
            return Theme.textSecondary
        } else if streakService.currentStreak < 3 {
            return Theme.accentGold
        } else if streakService.currentStreak < 7 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Stats

    private var streakStats: some View {
        HStack(spacing: Theme.spacingM) {
            statCard(
                title: "Best Streak",
                value: "\(streakService.bestStreak)",
                subtitle: "days",
                icon: "trophy.fill",
                color: Theme.accentGold
            )

            statCard(
                title: "Most Active",
                value: streakService.mostActiveWeekdayName,
                subtitle: "day of week",
                icon: "calendar",
                color: Theme.accentBlue
            )

            statCard(
                title: "Total Days",
                value: "\(streakService.totalActiveDays)",
                subtitle: "active days",
                icon: "checkmark.circle.fill",
                color: Theme.accentGreen
            )
        }
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    // MARK: - Weekly Heat Map

    private var weeklyHeatMap: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Theme.spacingS) {
                ForEach(streakService.weeklyHeatMapData()) { day in
                    VStack(spacing: 4) {
                        Text(day.dayLetter)
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)

                        Circle()
                            .fill(heatMapColor(for: day))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: day.hasActivity ? "checkmark" : "")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func heatMapColor(for day: DayActivity) -> Color {
        switch day.activityLevel {
        case 0: return Theme.surfaceElevated
        case 1: return Theme.accentGreen.opacity(0.3)
        case 2: return Theme.accentGreen.opacity(0.6)
        default: return Theme.accentGreen
        }
    }

    // MARK: - Consistency Score

    private var consistencyScore: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("Monthly Consistency")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(Int(streakService.monthlyConsistencyScore))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(consistencyColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(consistencyColor)
                        .frame(width: geometry.size.width * (streakService.monthlyConsistencyScore / 100), height: 8)
                }
            }
            .frame(height: 8)

            Text("You've been active on \(Int(streakService.monthlyConsistencyScore))% of days this month")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var consistencyColor: Color {
        let score = streakService.monthlyConsistencyScore
        if score >= 70 { return Theme.accentGreen }
        if score >= 40 { return Theme.accentGold }
        return Theme.accentRed
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: Theme.spacingS) {
            Button {
                showingReports = true
            } label: {
                Label("View Reports", systemImage: "doc.text")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingS)
                    .background(Theme.accentBlue.opacity(0.15))
                    .foregroundColor(Theme.accentBlue)
                    .cornerRadius(8)
            }

            HStack(spacing: Theme.spacingS) {
                Button {
                    generateReport()
                } label: {
                    Label("Generate PDF", systemImage: "doc.richtext")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingS)
                        .background(Theme.surfaceElevated)
                        .foregroundColor(Theme.textSecondary)
                        .cornerRadius(8)
                }

                Button {
                    generateBeliefMap()
                } label: {
                    Label("Belief Map", systemImage: "map")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingS)
                        .background(Theme.surfaceElevated)
                        .foregroundColor(Theme.textSecondary)
                        .cornerRadius(8)
                }
            }
        }
    }

    private func generateReport() {
        if let url = ReportService.shared.generateMonthlyReport(for: Date()) {
            NSWorkspace.shared.open(url)
        }
    }

    private func generateBeliefMap() {
        if let url = ReportService.shared.generateBeliefMap() {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Reports View

struct MacReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reports: [URL] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            reportsList
        }
        .background(Theme.background)
        .frame(width: 500, height: 400)
        .onAppear {
            reports = ReportService.shared.listReports()
        }
    }

    private var header: some View {
        HStack {
            Text("Reports")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.screenMargin)
        .background(Theme.surface)
    }

    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS) {
                ForEach(reports, id: \.self) { url in
                    reportRow(url: url)
                }

                if reports.isEmpty {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.4))
                        Text("No reports yet")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Text("Generate your first monthly report")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingXL)
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private func reportRow(url: URL) -> some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(Theme.accentRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text(url.path)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.forward.square")
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.spacingS)
            .background(Theme.surface)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacStreakView()
        .preferredColorScheme(.dark)
}
