import SwiftUI

// MARK: - Health Correlation Models

struct HealthCorrelation: Identifiable, Codable {
    let id: UUID
    var beliefId: UUID?
    var date: Date
    var beliefScore: Double
    var mood: Int // 1-10
    var sleepQuality: Double // 0-100
    var sleepHours: Double
    var stressLevel: Int // 1-10

    init(id: UUID = UUID(), beliefId: UUID? = nil, date: Date = Date(), beliefScore: Double, mood: Int, sleepQuality: Double, sleepHours: Double, stressLevel: Int) {
        self.id = id
        self.beliefId = beliefId
        self.date = date
        self.beliefScore = beliefScore
        self.mood = mood
        self.sleepQuality = sleepQuality
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
    }
}

struct CorrelationDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let beliefScore: Double
    let mood: Double
    let sleepQuality: Double
    let sleepHours: Double
    let stressLevel: Double
}

enum CorrelationChart: String, CaseIterable {
    case beliefVsMood = "Belief Score vs Mood"
    case beliefVsSleep = "Belief Score vs Sleep"
    case sleepTrend = "Sleep Quality Trend"
    case moodTrend = "Mood Trend"

    var icon: String {
        switch self {
        case .beliefVsMood: return "brain.head.profile"
        case .beliefVsSleep: return "bed.double.fill"
        case .sleepTrend: return "moon.stars.fill"
        case .moodTrend: return "face.smiling.fill"
        }
    }
}

// MARK: - MacHealthCorrelationView

@MainActor
struct MacHealthCorrelationView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedChart: CorrelationChart = .beliefVsMood
    @State private var correlations: [HealthCorrelation] = []
    @State private var isHealthKitAvailable = false
    @State private var isConnected = false
    @State private var showingConnectPrompt = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if !isConnected && !isHealthKitAvailable {
                noConnectionView
            } else if correlations.isEmpty {
                emptyStateView
            } else {
                chartContent
            }
        }
        .background(Theme.background)
        .onAppear {
            checkHealthKitStatus()
            loadCorrelations()
        }
    }

    private var headerView: some View {
        HStack {
            Text("Health Correlation")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            HStack(spacing: Theme.spacingS) {
                Circle()
                    .fill(isConnected ? Theme.accentGreen : Theme.textSecondary)
                    .frame(width: 8, height: 8)
                Text(isConnected ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            Button {
                showingConnectPrompt = true
            } label: {
                Text(isConnected ? "Manage" : "Connect iPhone")
                    .font(.caption)
                    .foregroundColor(Theme.accentGold)
            }
            .accessibilityLabel(isConnected ? "Manage health connection" : "Connect iPhone")
            .accessibilityHint("Connect your iPhone to sync health data")
        }
        .padding(Theme.screenMargin)
        .background(Theme.surface)
    }

    @ViewBuilder
    private var noConnectionView: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingM) {
                Text("Connect Your Health Data")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Link your iPhone to see how belief work correlates with your sleep, mood, and stress levels")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }
            VStack(spacing: Theme.spacingS) {
                HStack(spacing: Theme.spacingM) {
                    HealthKitFeature(icon: "bed.double.fill", title: "Sleep Quality", description: "Hours & restfulness")
                    HealthKitFeature(icon: "face.smiling.fill", title: "Mood", description: "Daily check-ins")
                }
                HStack(spacing: Theme.spacingM) {
                    HealthKitFeature(icon: "brain.head.profile", title: "Belief Scores", description: "Your evidence balance")
                    HealthKitFeature(icon: "waveform.path.ecg", title: "Stress Level", description: "HRV & patterns")
                }
            }
            .padding(.horizontal, Theme.screenMargin)

            Button {
                showingConnectPrompt = true
            } label: {
                Label("Connect iPhone", systemImage: "iphone.badge.play")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS)
                    .background(Theme.accentGold)
                    .cornerRadius(Theme.cornerRadiusPill)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Connect iPhone", isPresented: $showingConnectPrompt) {
            Button("Open Settings") {
                // In production: open Health app or companion app
                isConnected = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To sync health data from your iPhone, open the Axiom companion app and pair your devices.")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text("No Correlation Data Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Start tracking your belief work and health metrics to see correlations")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chartContent: some View {
        VStack(spacing: 0) {
            // Chart type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingS) {
                    ForEach(CorrelationChart.allCases, id: \.self) { chart in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedChart = chart
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: chart.icon)
                                    .font(.caption2)
                                Text(chart.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(selectedChart == chart ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, Theme.spacingS)
                            .padding(.vertical, Theme.spacingXS)
                            .background(selectedChart == chart ? Theme.accentGold.opacity(0.15) : Color.clear)
                            .cornerRadius(Theme.cornerRadiusS)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenMargin)
                .padding(.vertical, Theme.spacingS)
            }

            // Chart
            CorrelationLineChart(
                dataPoints: correlationDataPoints,
                chartType: selectedChart
            )
            .frame(height: 300)
            .padding(Theme.screenMargin)

            // Stats
            correlationStats
        }
    }

    private var correlationStats: some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingM) {
                StatCard(title: "Avg Sleep", value: String(format: "%.1fh", averageSleep), icon: "bed.double.fill", color: Theme.accentBlue)
                StatCard(title: "Avg Mood", value: String(format: "%.1f", averageMood), icon: "face.smiling.fill", color: Theme.accentGold)
            }
            HStack(spacing: Theme.spacingM) {
                StatCard(title: "Avg Belief", value: String(format: "%.0f%%", averageBeliefScore), icon: "brain.head.profile", color: Theme.accentGreen)
                StatCard(title: "Avg Stress", value: String(format: "%.1f", averageStress), icon: "waveform.path.ecg", color: Theme.accentRed)
            }
        }
        .padding(Theme.screenMargin)
    }

    private var correlationDataPoints: [CorrelationDataPoint] {
        correlations.map { corr in
            CorrelationDataPoint(
                id: corr.id,
                date: corr.date,
                beliefScore: corr.beliefScore,
                mood: Double(corr.mood) * 10,
                sleepQuality: corr.sleepQuality,
                sleepHours: corr.sleepHours * 10,
                stressLevel: Double(corr.stressLevel) * 10
            )
        }
    }

    private var averageSleep: Double {
        guard !correlations.isEmpty else { return 0 }
        return correlations.reduce(0) { $0 + $1.sleepHours } / Double(correlations.count)
    }

    private var averageMood: Double {
        guard !correlations.isEmpty else { return 0 }
        return Double(correlations.reduce(0) { $0 + $1.mood }) / Double(correlations.count)
    }

    private var averageBeliefScore: Double {
        guard !correlations.isEmpty else { return 0 }
        return correlations.reduce(0) { $0 + $1.beliefScore } / Double(correlations.count)
    }

    private var averageStress: Double {
        guard !correlations.isEmpty else { return 0 }
        return Double(correlations.reduce(0) { $0 + $1.stressLevel }) / Double(correlations.count)
    }

    private func checkHealthKitStatus() {
        // On macOS, HealthKit is not directly available unless using Mac Catalyst
        // In a real implementation, we'd check for HealthKit authorization
        #if canImport(HealthKit)
        isHealthKitAvailable = false
        #else
        isHealthKitAvailable = false
        #endif
    }

    private func loadCorrelations() {
        if let data = UserDefaults.standard.data(forKey: "healthCorrelations"),
           let decoded = try? JSONDecoder().decode([HealthCorrelation].self, from: data) {
            correlations = decoded
        }
        // For demo, create sample data if empty
        if correlations.isEmpty {
            correlations = generateSampleCorrelations()
        }
    }

    private func generateSampleCorrelations() -> [HealthCorrelation] {
        var samples: [HealthCorrelation] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let beliefScore = Double.random(in: 40...85)
            let mood = Int.random(in: 4...9)
            let sleepQuality = Double.random(in: 50...95)
            let sleepHours = Double.random(in: 5.5...9.0)
            let stress = Int.random(in: 2...7)

            let corr = HealthCorrelation(
                date: date,
                beliefScore: beliefScore,
                mood: mood,
                sleepQuality: sleepQuality,
                sleepHours: sleepHours,
                stressLevel: stress
            )
            samples.append(corr)
        }

        return samples.reversed()
    }
}

// MARK: - HealthKit Feature Card

struct HealthKitFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.accentGold)
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Correlation Line Chart

struct CorrelationLineChart: View {
    let dataPoints: [CorrelationDataPoint]
    let chartType: CorrelationChart

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                gridLines(in: geometry.size)

                // Draw lines
                if dataPoints.count >= 2 {
                    // Primary line
                    linePath(for: primaryValue, in: geometry.size)
                        .stroke(Theme.accentGold, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Secondary line (if applicable)
                    if chartType == .beliefVsMood || chartType == .beliefVsSleep {
                        linePath(for: secondaryValue, in: geometry.size)
                            .stroke(Theme.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 3]))
                    }

                    // Data points
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                        Circle()
                            .fill(Theme.accentGold)
                            .frame(width: 8, height: 8)
                            .position(pointPosition(for: point, at: index, in: geometry.size))
                    }
                }

                // Legend
                VStack {
                    HStack {
                        Spacer()
                        chartLegend
                    }
                    Spacer()
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var chartLegend: some View {
        HStack(spacing: Theme.spacingM) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.accentGold)
                    .frame(width: 8, height: 8)
                Text(primaryLabel)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            if chartType == .beliefVsMood || chartType == .beliefVsSleep {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.accentBlue)
                        .frame(width: 8, height: 8)
                    Text(secondaryLabel)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, 4)
        .background(Theme.surfaceElevated.opacity(0.8))
        .cornerRadius(Theme.cornerRadiusS)
    }

    private var primaryLabel: String {
        switch chartType {
        case .beliefVsMood, .beliefVsSleep: return primaryValue == .belief ? "Belief Score" : (chartType == .sleepTrend ? "Sleep Quality" : "Mood")
        case .sleepTrend: return "Sleep Quality"
        case .moodTrend: return "Mood"
        }
    }

    private var secondaryLabel: String {
        switch chartType {
        case .beliefVsMood: return "Mood"
        case .beliefVsSleep: return "Sleep"
        default: return ""
        }
    }

    private var primaryValue: ChartValue {
        switch chartType {
        case .beliefVsMood: return .belief
        case .beliefVsSleep: return .belief
        case .sleepTrend: return .sleep
        case .moodTrend: return .mood
        }
    }

    private var secondaryValue: ChartValue {
        switch chartType {
        case .beliefVsMood: return .mood
        case .beliefVsSleep: return .sleep
        default: return .belief
        }
    }

    private enum ChartValue {
        case belief, mood, sleep, stress
    }

    private func gridLines(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { i in
                Divider()
                    .background(Theme.border.opacity(0.3))
                Spacer()
            }
        }
    }

    private func linePath(for value: ChartValue, in size: CGSize) -> Path {
        Path { path in
            guard dataPoints.count >= 2 else { return }

            let width = size.width
            let height = size.height
            let stepX = width / CGFloat(dataPoints.count - 1)

            for (index, point) in dataPoints.enumerated() {
                let x = CGFloat(index) * stepX
                let y = height - (normalizedValue(for: point, value: value) * height)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    private func pointPosition(for point: CorrelationDataPoint, at index: Int, in size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height
        let stepX = width / CGFloat(max(dataPoints.count - 1, 1))
        let x = CGFloat(index) * stepX
        let y = height - (normalizedValue(for: point, value: primaryValue) * height)
        return CGPoint(x: x, y: y)
    }

    private func normalizedValue(for point: CorrelationDataPoint, value: ChartValue) -> CGFloat {
        switch value {
        case .belief: return CGFloat(point.beliefScore / 100)
        case .mood: return CGFloat(point.mood / 100)
        case .sleep: return CGFloat(point.sleepQuality / 100)
        case .stress: return CGFloat(point.stressLevel / 100)
        }
    }
}
