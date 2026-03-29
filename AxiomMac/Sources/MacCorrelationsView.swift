import SwiftUI
import Charts

// MARK: - MacCorrelationsView

/// R23: Comprehensive correlations view combining health, calendar, and location insights

struct MacCorrelationsView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedTab: CorrelationTab = .health
    @State private var healthCorrelations: [HealthIntegrationService.HealthCorrelation] = []
    @State private var healthInsights: [HealthIntegrationService.Insight] = []
    @State private var calendarInsights: [CalendarIntegrationService.CalendarInsight] = []
    @State private var locationInsights: [LocationPatternService.LocationInsight] = []
    @State private var isLoading = true

    enum CorrelationTab: String, CaseIterable {
        case health = "Health"
        case calendar = "Calendar"
        case location = "Location"

        var icon: String {
            switch self {
            case .health: return "heart.text.square.fill"
            case .calendar: return "calendar.badge.clock"
            case .location: return "location.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if isLoading {
                loadingView
            } else {
                tabContent
            }
        }
        .background(Theme.background)
        .onAppear {
            loadAllData()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: Theme.spacingM) {
            Text("Correlations")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            tabPicker
        }
        .padding(Theme.screenMargin)
        .background(Theme.surface)
    }

    private var tabPicker: some View {
        HStack(spacing: Theme.spacingS) {
            ForEach(CorrelationTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: Theme.spacingXS) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                    .background(selectedTab == tab ? Theme.accentGold.opacity(0.15) : Color.clear)
                    .cornerRadius(Theme.cornerRadiusPill)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.spacingM) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing correlations...")
                .font(.callout)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .health:
            healthContent
        case .calendar:
            calendarContent
        case .location:
            locationContent
        }
    }

    // MARK: - Health Content

    private var healthContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Belief Score Chart
                beliefScoreChart

                // Insights
                insightsSection(title: "Insights", insights: healthInsights)
            }
            .padding(Theme.screenMargin)
        }
    }

    private var beliefScoreChart: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Belief Score Trend")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if healthCorrelations.isEmpty {
                emptyChartView
            } else {
                Chart {
                    ForEach(healthCorrelations) { correlation in
                        LineMark(
                            x: .value("Date", correlation.date),
                            y: .value("Score", correlation.beliefScore)
                        )
                        .foregroundStyle(Theme.accentGold)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", correlation.date),
                            y: .value("Score", correlation.beliefScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accentGold.opacity(0.3), Theme.accentGold.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // Correlation Stats
            if !healthCorrelations.isEmpty {
                correlationStats
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var correlationStats: some View {
        HStack(spacing: Theme.spacingM) {
            StatCard(
                title: "Avg Sleep",
                value: String(format: "%.1fh", averageSleep),
                icon: "bed.double.fill",
                color: Theme.accentBlue
            )
            StatCard(
                title: "Avg Mood",
                value: String(format: "%.1f", averageMood),
                icon: "face.smiling.fill",
                color: Theme.accentGold
            )
            StatCard(
                title: "Avg Stress",
                value: String(format: "%.1f", averageStress),
                icon: "waveform.path.ecg",
                color: Theme.accentRed
            )
        }
    }

    private var emptyChartView: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary.opacity(0.4))
            Text("No correlation data yet")
                .font(.callout)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                if calendarInsights.isEmpty {
                    emptyCalendarView
                } else {
                    ForEach(calendarInsights) { insight in
                        CalendarInsightCard(insight: insight)
                    }
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var emptyCalendarView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text("No Calendar Patterns Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Calendar insights will appear once you have calendar access and belief activity")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Location Content

    private var locationContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                if locationInsights.isEmpty {
                    emptyLocationView
                } else {
                    ForEach(locationInsights) { insight in
                        LocationInsightCard(insight: insight)
                    }
                }
            }
            .padding(Theme.screenMargin)
        }
    }

    private var emptyLocationView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "location.fill")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text("No Location Patterns Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Location insights will appear as you use Axiom in different places")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Insights Section

    private func insightsSection(title: String, insights: [HealthIntegrationService.Insight]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if insights.isEmpty {
                Text("Not enough data for insights yet")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var averageSleep: Double {
        let withSleep = healthCorrelations.compactMap { $0.sleepHours }
        guard !withSleep.isEmpty else { return 0 }
        return withSleep.reduce(0, +) / Double(withSleep.count)
    }

    private var averageMood: Double {
        let withMood = healthCorrelations.compactMap { $0.moodScore }
        guard !withMood.isEmpty else { return 0 }
        return Double(withMood.reduce(0, +)) / Double(withMood.count)
    }

    private var averageStress: Double {
        let withStress = healthCorrelations.compactMap { $0.stressLevel }
        guard !withStress.isEmpty else { return 0 }
        return Double(withStress.reduce(0, +)) / Double(withStress.count)
    }

    // MARK: - Data Loading

    private func loadAllData() {
        isLoading = true

        Task {
            // Load health data
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            let dateRange = startDate...endDate

            let healthService = HealthIntegrationService.shared
            healthCorrelations = await healthService.fetchCorrelationData(for: dateRange)
            healthInsights = healthService.generateCorrelationInsights(data: healthCorrelations)

            // Load calendar insights
            let calendarService = CalendarIntegrationService.shared
            let events = await calendarService.fetchEvents(from: startDate, to: endDate)
            calendarInsights = calendarService.detectCalendarPatterns(events: events)

            // Load location insights
            let locationService = LocationPatternService.shared
            locationInsights = locationService.generateLocationInsights()

            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: HealthIntegrationService.Insight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(insight.strength.rawValue)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(4)
            }

            Text(insight.description)
                .font(.callout)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var categoryIcon: String {
        switch insight.category {
        case .sleep: return "bed.double.fill"
        case .mood: return "face.smiling.fill"
        case .stress: return "waveform.path.ecg"
        case .activity: return "figure.walk"
        case .general: return "lightbulb.fill"
        }
    }

    private var categoryColor: Color {
        switch insight.category {
        case .sleep: return Theme.accentBlue
        case .mood: return Theme.accentGold
        case .stress: return Theme.accentRed
        case .activity: return Theme.accentGreen
        case .general: return Theme.accentBlue
        }
    }
}

// MARK: - Calendar Insight Card

struct CalendarInsightCard: View {
    let insight: CalendarIntegrationService.CalendarInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(categoryColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.trigger)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)

                    Text("\(insight.frequency) events")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Text(insight.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(4)
            }

            if !insight.beliefPatterns.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Related Beliefs:")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    ForEach(insight.beliefPatterns, id: \.self) { pattern in
                        HStack(spacing: Theme.spacingXS) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(Theme.accentGold)
                            Text(pattern)
                                .font(.callout)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var categoryColor: Color {
        switch insight.category {
        case .work: return Theme.accentBlue
        case .social: return Theme.accentPurple
        case .personal: return Theme.accentGold
        case .health: return Theme.accentGreen
        case .general: return Theme.textSecondary
        }
    }
}

// MARK: - Location Insight Card

struct LocationInsightCard: View {
    let insight: LocationPatternService.LocationInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: locationIcon)
                    .font(.title2)
                    .foregroundColor(Theme.accentGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.location)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)

                    Text("\(insight.beliefWorkFrequency) belief sessions")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Avg \(insight.averageScore)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)
                    Text(insight.timeOfDay.rawValue)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Text(insight.description)
                .font(.callout)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.spacingM) {
                Label(insight.mostCommonBeliefCategory, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accentBlue)

                if let dayOfWeek = insight.dayOfWeek {
                    Label(dayOfWeek, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var locationIcon: String {
        LocationPatternService.KnownLocation(rawValue: insight.location)?.icon ?? "mappin.circle.fill"
    }
}
