import Foundation

/// Tracks belief work streaks and activity metrics
@MainActor
final class StreakService: ObservableObject {
    static let shared = StreakService()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var mostActiveWeekday: Int = 1 // 1 = Sunday
    @Published private(set) var monthlyConsistencyScore: Double = 0
    @Published private(set) var totalActiveDays: Int = 0
    @Published private(set) var lastActiveDate: Date?

    private let userDefaults = UserDefaults.standard
    private let streakKey = "axiom_streak_data"
    private let calendar = Calendar.current

    struct StreakData: Codable {
        var currentStreak: Int = 0
        var bestStreak: Int = 0
        var lastActiveDate: Date?
        var weekdayCounts: [Int: Int] = [:] // weekday (1-7) -> count
        var monthlyScores: [String: Double] = [:] // "YYYY-MM" -> consistency score
    }

    private init() {
        loadStreakData()
        updateStreak()
    }

    // MARK: - Activity Tracking

    func recordActivity() {
        let today = calendar.startOfDay(for: Date())

        var data = loadStreakData()

        // Check if already recorded today
        if let lastDate = data.lastActiveDate,
           calendar.isDate(lastDate, inSameDayAs: today) {
            return // Already recorded today
        }

        // Update streak
        if let lastDate = data.lastActiveDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastDate, inSameDayAs: yesterday) {
                data.currentStreak += 1
            } else if !calendar.isDate(lastDate, inSameDayAs: today) {
                data.currentStreak = 1 // Streak broken, start new
            }
        } else {
            data.currentStreak = 1
        }

        data.lastActiveDate = today

        if data.currentStreak > data.bestStreak {
            data.bestStreak = data.currentStreak
        }

        // Track weekday
        let weekday = calendar.component(.weekday, from: today)
        data.weekdayCounts[weekday, default: 0] += 1

        // Update most active weekday
        DispatchQueue.main.async {
            self.mostActiveWeekday = data.weekdayCounts.max(by: { $0.value < $1.value })?.key ?? 1
        }

        saveStreakData(data)
        updatePublishedValues(from: data)
    }

    func updateStreak() {
        let data = loadStreakData()
        let today = calendar.startOfDay(for: Date())

        if let lastDate = data.lastActiveDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

            if calendar.isDate(lastDate, inSameDayAs: yesterday) {
                // Streak continues
                var updatedData = data
                updatedData.currentStreak = data.currentStreak
                saveStreakData(updatedData)
            } else if !calendar.isDate(lastDate, inSameDayAs: today) {
                // Streak broken
                var updatedData = data
                updatedData.currentStreak = 0
                saveStreakData(updatedData)
            }
        }

        updatePublishedValues(from: loadStreakData())
        updateMonthlyConsistency()
    }

    private func updatePublishedValues(from data: StreakData) {
        DispatchQueue.main.async {
            self.currentStreak = data.currentStreak
            self.bestStreak = data.bestStreak
            self.lastActiveDate = data.lastActiveDate
            self.totalActiveDays = data.weekdayCounts.values.reduce(0, +)
        }
    }

    private func updateMonthlyConsistency() {
        let beliefs = DatabaseService.shared.allBeliefs
        let calendar = Calendar.current
        let now = Date()
        let monthKey = DateFormatter().string(from: now)

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let today = calendar.component(.day, from: now)

        var activeDaysThisMonth = Set<Int>()
        for belief in beliefs {
            for evidence in belief.evidenceItems {
                if evidence.createdAt >= startOfMonth {
                    let day = calendar.component(.day, from: evidence.createdAt)
                    activeDaysThisMonth.insert(day)
                }
            }
        }

        let data = loadStreakData()
        if let monthData = data.monthlyScores[monthKey] {
            monthlyConsistencyScore = monthData
        } else {
            let consistency = Double(activeDaysThisMonth.count) / Double(today) * 100
            monthlyConsistencyScore = min(100, consistency)
        }
    }

    // MARK: - Heat Map Data

    func weeklyHeatMapData() -> [DayActivity] {
        let data = loadStreakData()
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let weekday = calendar.component(.weekday, from: date)

            var hasActivity = false
            if let lastActive = data.lastActiveDate {
                hasActivity = calendar.isDate(lastActive, inSameDayAs: date)
            }

            let count = data.weekdayCounts[weekday] ?? 0
            let level: Int
            if count == 0 { level = 0 }
            else if count <= 2 { level = 1 }
            else if count <= 5 { level = 2 }
            else { level = 3 }

            return DayActivity(
                date: date,
                weekday: weekday,
                hasActivity: hasActivity,
                activityLevel: level
            )
        }
    }

    // MARK: - Streak Data Persistence

    private func loadStreakData() -> StreakData {
        guard let json = userDefaults.string(forKey: streakKey),
              let data = json.data(using: .utf8) else {
            return StreakData()
        }
        return (try? JSONDecoder().decode(StreakData.self, from: data)) ?? StreakData()
    }

    private func saveStreakData(_ data: StreakData) {
        guard let json = try? JSONEncoder().encode(data),
              let string = String(data: json, encoding: .utf8) else { return }
        userDefaults.set(string, forKey: streakKey)
    }

    // MARK: - Motivational

    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak < 3 {
            return "\(currentStreak) day streak — keep building!"
        } else if currentStreak < 7 {
            return "Nice! \(currentStreak) days — you're on fire! 🔥"
        } else if currentStreak < 14 {
            return "\(currentStreak) days! You're developing a powerful habit."
        } else if currentStreak < 30 {
            return "Incredible \(currentStreak)-day streak! You're mastering your beliefs."
        } else {
            return "\(currentStreak) days and counting! You're a belief audit champion."
        }
    }

    var mostActiveWeekdayName: String {
        calendar.weekdaySymbols[mostActiveWeekday - 1]
    }
}

// MARK: - Supporting Types

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let weekday: Int
    let hasActivity: Bool
    let activityLevel: Int // 0-3

    var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
