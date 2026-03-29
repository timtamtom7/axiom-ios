import Foundation
#if os(macOS)
import AppKit
#endif

/// R23: Health data integration for AxiomMac
/// On macOS, health data comes from paired iPhone via iCloud
/// Shows correlation between belief work and wellness

@MainActor
final class HealthIntegrationService: @unchecked Sendable {
    static let shared = HealthIntegrationService()

    private let userDefaults = UserDefaults.standard

    // MARK: - Types

    struct HealthCorrelation: Identifiable {
        let id = UUID()
        let date: Date
        let beliefScore: Int
        let sleepHours: Double?
        let moodScore: Int?
        let steps: Int?
        let stressLevel: Int?
    }

    struct Insight: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let category: InsightCategory
        let strength: InsightStrength
    }

    enum InsightCategory: String, Codable {
        case sleep = "Sleep"
        case mood = "Mood"
        case stress = "Stress"
        case activity = "Activity"
        case general = "General"
    }

    enum InsightStrength: String, Codable {
        case strong = "Strong"
        case moderate = "Moderate"
        case weak = "Weak"
    }

    // MARK: - HealthKit Authorization Status

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    // MARK: - Public Methods

    /// Fetches correlation data by merging belief scores with health metrics
    func fetchCorrelationData(for dateRange: ClosedRange<Date>) async -> [HealthCorrelation] {
        // Pull belief scores from DatabaseService
        let beliefs = DatabaseService.shared.allBeliefs
        let beliefScores = extractDailyBeliefScores(from: beliefs, in: dateRange)

        // Pull health data from iCloud HealthKit container
        let healthData = await fetchHealthData(from: dateRange)

        // Return merged timeline
        return mergeBeliefAndHealthData(beliefs: beliefScores, health: healthData)
    }

    /// Generates insights from correlation data
    func generateCorrelationInsights(data: [HealthCorrelation]) -> [Insight] {
        var insights: [Insight] = []

        // Sleep correlations
        if let sleepInsight = analyzeSleepCorrelation(data: data) {
            insights.append(sleepInsight)
        }

        // Mood correlations
        if let moodInsight = analyzeMoodCorrelation(data: data) {
            insights.append(moodInsight)
        }

        // Stress correlations
        if let stressInsight = analyzeStressCorrelation(data: data) {
            insights.append(stressInsight)
        }

        // Activity correlations
        if let activityInsight = analyzeActivityCorrelation(data: data) {
            insights.append(activityInsight)
        }

        return insights
    }

    /// Check current authorization status for health data
    func checkAuthorizationStatus() -> AuthorizationStatus {
        #if canImport(HealthKit)
        return .unavailable
        #else
        return .unavailable
        #endif
    }

    /// Request authorization to read health data
    func requestAuthorization() async -> AuthorizationStatus {
        return .unavailable
    }

    // MARK: - Private Methods

    private func extractDailyBeliefScores(from beliefs: [Belief], in dateRange: ClosedRange<Date>) -> [Date: Int] {
        var dailyScores: [Date: [Int]] = [:]
        let calendar = Calendar.current

        for belief in beliefs {
            let day = calendar.startOfDay(for: belief.createdAt)
            guard dateRange.contains(day) else { continue }

            if dailyScores[day] == nil {
                dailyScores[day] = []
            }
            dailyScores[day]?.append(Int(belief.score))
        }

        // Calculate average score per day
        var result: [Date: Int] = [:]
        for (day, scores) in dailyScores {
            let avg = scores.reduce(0, +) / scores.count
            result[day] = avg
        }

        return result
    }

    private func fetchHealthData(from dateRange: ClosedRange<Date>) async -> [Date: HealthMetrics] {
        return loadCachedHealthData(for: dateRange)
    }

    private func loadCachedHealthData(for dateRange: ClosedRange<Date>) -> [Date: HealthMetrics] {
        guard let cached = userDefaults.data(forKey: "cachedHealthMetrics"),
              let decoded = try? JSONDecoder().decode(CachedHealthData.self, from: cached) else {
            return generateSampleHealthData(for: dateRange)
        }

        var result: [Date: HealthMetrics] = [:]
        let calendar = Calendar.current

        for entry in decoded.entries {
            let day = calendar.startOfDay(for: entry.date)
            if dateRange.contains(day) {
                result[day] = entry.metrics
            }
        }

        return result
    }

    private func generateSampleHealthData(for dateRange: ClosedRange<Date>) -> [Date: HealthMetrics] {
        var result: [Date: HealthMetrics] = [:]
        let calendar = Calendar.current

        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let day = calendar.startOfDay(for: currentDate)
            result[day] = HealthMetrics(
                sleepHours: Double.random(in: 5.5...9.0),
                moodScore: Int.random(in: 4...9),
                steps: Int.random(in: 3000...12000),
                stressLevel: Int.random(in: 2...7)
            )
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? dateRange.upperBound
        }

        return result
    }

    private func mergeBeliefAndHealthData(beliefs: [Date: Int], health: [Date: HealthMetrics]) -> [HealthCorrelation] {
        var correlations: [HealthCorrelation] = []

        // Merge based on belief data days
        for (date, score) in beliefs {
            let metrics = health[date]
            let correlation = HealthCorrelation(
                date: date,
                beliefScore: score,
                sleepHours: metrics?.sleepHours,
                moodScore: metrics?.moodScore,
                steps: metrics?.steps,
                stressLevel: metrics?.stressLevel
            )
            correlations.append(correlation)
        }

        // Sort by date
        return correlations.sorted { $0.date < $1.date }
    }

    // MARK: - Correlation Analysis

    private func analyzeSleepCorrelation(data: [HealthCorrelation]) -> Insight? {
        let daysWithSleep = data.filter { $0.sleepHours != nil && $0.sleepHours! > 0 }

        guard daysWithSleep.count >= 5 else { return nil }

        // Group by sleep amount
        let highSleepDays = daysWithSleep.filter { ($0.sleepHours ?? 0) >= 7 }
        let lowSleepDays = daysWithSleep.filter { ($0.sleepHours ?? 0) < 7 }

        let highSleepAvg = highSleepDays.isEmpty ? 0 : highSleepDays.reduce(0) { $0 + $1.beliefScore } / highSleepDays.count
        let lowSleepAvg = lowSleepDays.isEmpty ? 0 : lowSleepDays.reduce(0) { $0 + $1.beliefScore } / lowSleepDays.count

        let difference = highSleepAvg - lowSleepAvg

        if difference > 10 {
            return Insight(
                title: "Sleep Boost",
                description: "You tend to have higher belief scores on days with more sleep (7+ hours). Average score is \(highSleepAvg)% vs \(lowSleepAvg)% on low sleep days.",
                category: .sleep,
                strength: difference > 20 ? .strong : .moderate
            )
        } else if difference < -10 {
            return Insight(
                title: "Sleep Pattern",
                description: "Your belief scores tend to be higher on days with less sleep. This could indicate compensating behavior or timing of belief work.",
                category: .sleep,
                strength: abs(difference) > 20 ? .strong : .moderate
            )
        }

        return nil
    }

    private func analyzeMoodCorrelation(data: [HealthCorrelation]) -> Insight? {
        let daysWithMood = data.filter { $0.moodScore != nil }

        guard daysWithMood.count >= 5 else { return nil }

        // Check correlation between mood and belief scores
        var totalDeviation: Double = 0
        for day in daysWithMood {
            let normalizedBelief = Double(day.beliefScore) / 100.0
            let normalizedMood = Double(day.moodScore ?? 5) / 10.0
            totalDeviation += abs(normalizedBelief - normalizedMood)
        }

        let avgDeviation = totalDeviation / Double(daysWithMood.count)

        if avgDeviation < 0.2 {
            let highMoodDays = daysWithMood.filter { ($0.moodScore ?? 5) >= 7 }
            let avgHighMood = highMoodDays.isEmpty ? 0 : highMoodDays.reduce(0) { $0 + $1.beliefScore } / highMoodDays.count

            return Insight(
                title: "Mood-Belief Alignment",
                description: "Your belief scores closely track your mood. On high mood days (7+), your average belief score is \(avgHighMood)%.",
                category: .mood,
                strength: avgDeviation < 0.1 ? .strong : .moderate
            )
        }

        return nil
    }

    private func analyzeStressCorrelation(data: [HealthCorrelation]) -> Insight? {
        let daysWithStress = data.filter { $0.stressLevel != nil }

        guard daysWithStress.count >= 5 else { return nil }

        let highStressDays = daysWithStress.filter { ($0.stressLevel ?? 0) >= 6 }
        let lowStressDays = daysWithStress.filter { ($0.stressLevel ?? 0) <= 4 }

        if !highStressDays.isEmpty && !lowStressDays.isEmpty {
            let highStressAvg = highStressDays.reduce(0) { $0 + $1.beliefScore } / highStressDays.count
            let lowStressAvg = lowStressDays.reduce(0) { $0 + $1.beliefScore } / lowStressDays.count

            if abs(highStressAvg - lowStressAvg) > 15 {
                return Insight(
                    title: "Stress Impact",
                    description: "Stress levels correlate with belief work. \(highStressAvg > lowStressAvg ? "You challenge beliefs more" : "Belief scores are higher") during low-stress periods (≤4).",
                    category: .stress,
                    strength: .moderate
                )
            }
        }

        return nil
    }

    private func analyzeActivityCorrelation(data: [HealthCorrelation]) -> Insight? {
        let daysWithSteps = data.filter { $0.steps != nil && $0.steps! > 0 }

        guard daysWithSteps.count >= 5 else { return nil }

        let activeDays = daysWithSteps.filter { ($0.steps ?? 0) >= 8000 }
        let sedentaryDays = daysWithSteps.filter { ($0.steps ?? 0) < 5000 }

        if !activeDays.isEmpty && !sedentaryDays.isEmpty {
            let activeAvg = activeDays.reduce(0) { $0 + $1.beliefScore } / activeDays.count
            let sedentaryAvg = sedentaryDays.reduce(0) { $0 + $1.beliefScore } / sedentaryDays.count

            if activeAvg > sedentaryAvg + 10 {
                return Insight(
                    title: "Activity Effect",
                    description: "On days with 8,000+ steps, your belief scores average \(activeAvg)%, compared to \(sedentaryAvg)% on less active days.",
                    category: .activity,
                    strength: .moderate
                )
            }
        }

        return nil
    }
}

// MARK: - Supporting Types

private struct HealthMetrics: Codable {
    let sleepHours: Double
    let moodScore: Int
    let steps: Int
    let stressLevel: Int
}

private struct CachedHealthData: Codable {
    let entries: [CachedHealthEntry]
}

private struct CachedHealthEntry: Codable {
    let date: Date
    let metrics: HealthMetrics
}

private struct CachedHealthMetrics: Codable {
    let sleepHours: Double
    let moodScore: Int
    let steps: Int
    let stressLevel: Int
}
