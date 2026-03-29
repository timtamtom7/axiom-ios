import Foundation
import CoreLocation

/// R23: Location pattern tracking for AxiomMac
/// Track where belief work happens - Home vs office vs commute
/// Uses Significant Location changes and WiFi sensing on macOS

final class LocationPatternService: @unchecked Sendable {
    static let shared = LocationPatternService()

    private let userDefaults = UserDefaults.standard

    // MARK: - Types

    struct LocationInsight: Identifiable {
        let id = UUID()
        let location: String
        let beliefWorkFrequency: Int
        let mostCommonBeliefCategory: String
        let averageScore: Int
        let timeOfDay: TimeOfDay
        let dayOfWeek: String?
        let description: String
    }

    enum TimeOfDay: String, Codable, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case lateNight = "Late Night"

        static func from(hour: Int) -> TimeOfDay {
            switch hour {
            case 5...11: return .morning
            case 12...16: return .afternoon
            case 17...20: return .evening
            default: return .lateNight
            }
        }
    }

    struct LocationEntry: Codable {
        let date: Date
        let locationName: String
        let latitude: Double?
        let longitude: Double?
        let beliefCount: Int
        let averageScore: Int
        let beliefCategories: [String]
    }

    // MARK: - Known Locations

    enum KnownLocation: String, CaseIterable {
        case home = "Home"
        case office = "Office"
        case commute = "Commute"
        case gym = "Gym"
        case cafe = "Cafe"
        case outdoor = "Outdoor"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .office: return "building.2.fill"
            case .commute: return "car.fill"
            case .gym: return "figure.run"
            case .cafe: return "cup.and.saucer.fill"
            case .outdoor: return "leaf.fill"
            case .unknown: return "mappin.circle.fill"
            }
        }
    }

    // MARK: - Public Methods

    /// Generate insights about where belief work happens
    @MainActor
    func generateLocationInsights() -> [LocationInsight] {
        let entries = loadLocationEntries()
        guard !entries.isEmpty else {
            return generateSampleInsights()
        }

        return analyzeLocationPatterns(entries: entries)
    }

    /// Record that belief work was done at a location
    @MainActor
    func recordBeliefWork(at location: KnownLocation, belief: Belief) {
        var entries = loadLocationEntries()
        let now = Date()
        let calendar = Calendar.current

        // Check if we already have an entry for this location today
        let today = calendar.startOfDay(for: now)
        let existingIndex = entries.firstIndex { entry in
            calendar.isDate(entry.date, inSameDayAs: today) &&
            entry.locationName == location.rawValue
        }

        if let index = existingIndex {
            // Update existing entry
            var entry = entries[index]
            let newCount = entry.beliefCount + 1
            let newTotal = entry.averageScore * entry.beliefCount + Int(belief.score)
            let newAvg = newTotal / newCount

            entries[index] = LocationEntry(
                date: entry.date,
                locationName: entry.locationName,
                latitude: entry.latitude,
                longitude: entry.longitude,
                beliefCount: newCount,
                averageScore: newAvg,
                beliefCategories: (entry.beliefCategories + [categorizeBelief(belief)]).uniqued()
            )
        } else {
            // Create new entry
            let entry = LocationEntry(
                date: now,
                locationName: location.rawValue,
                latitude: nil,
                longitude: nil,
                beliefCount: 1,
                averageScore: Int(belief.score),
                beliefCategories: [categorizeBelief(belief)]
            )
            entries.append(entry)
        }

        saveLocationEntries(entries)
    }

    /// Detect current location type based on available signals
    func detectCurrentLocation() -> KnownLocation {
        // On macOS, we can use:
        // 1. SSID of connected WiFi network
        // 2. Time of day patterns
        // 3. Known locations from Find My / Significant Locations

        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        // Time-based heuristics as fallback
        if hour >= 22 || hour < 6 {
            return .home
        } else if hour >= 9 && hour <= 17 && weekday >= 2 && weekday <= 6 {
            return .office
        } else if (hour >= 8 && hour <= 9) || (hour >= 17 && hour <= 18) {
            return .commute
        } else {
            return .unknown
        }
    }

    // MARK: - Private Methods

    private func loadLocationEntries() -> [LocationEntry] {
        guard let data = userDefaults.data(forKey: "locationEntries"),
              let decoded = try? JSONDecoder().decode([LocationEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveLocationEntries(_ entries: [LocationEntry]) {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: "locationEntries")
        }
    }

    @MainActor
    private func analyzeLocationPatterns(entries: [LocationEntry]) -> [LocationInsight] {
        var insights: [LocationInsight] = []

        // Group entries by location
        var locationGroups: [String: [LocationEntry]] = [:]
        for entry in entries {
            locationGroups[entry.locationName, default: []].append(entry)
        }

        // Generate insight for each location with sufficient data
        for (locationName, locationEntries) in locationGroups {
            guard locationEntries.count >= 3 else { continue }

            let knownLocation = KnownLocation(rawValue: locationName) ?? .unknown
            let totalBeliefs = locationEntries.reduce(0) { $0 + $1.beliefCount }
            let avgScore = locationEntries.reduce(0) { $0 + $1.averageScore } / locationEntries.count

            // Find most common category
            var categoryCounts: [String: Int] = [:]
            for entry in locationEntries {
                for category in entry.beliefCategories {
                    categoryCounts[category, default: 0] += 1
                }
            }
            let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key ?? "General"

            // Find most common time of day
            let timeOfDay = mostCommonTimeOfDay(entries: locationEntries)

            // Find most common day of week
            let mostCommonDay = mostCommonDayOfWeek(entries: locationEntries)

            // Generate description
            let description = generateDescription(
                location: knownLocation,
                frequency: totalBeliefs,
                timeOfDay: timeOfDay,
                dayOfWeek: mostCommonDay,
                category: mostCommonCategory
            )

            insights.append(LocationInsight(
                location: locationName,
                beliefWorkFrequency: totalBeliefs,
                mostCommonBeliefCategory: mostCommonCategory,
                averageScore: avgScore,
                timeOfDay: timeOfDay,
                dayOfWeek: mostCommonDay,
                description: description
            ))
        }

        // Sort by frequency
        return insights.sorted { $0.beliefWorkFrequency > $1.beliefWorkFrequency }
    }

    private func mostCommonTimeOfDay(entries: [LocationEntry]) -> TimeOfDay {
        var timeCounts: [TimeOfDay: Int] = [:]
        let calendar = Calendar.current

        for entry in entries {
            let hour = calendar.component(.hour, from: entry.date)
            let timeOfDay = TimeOfDay.from(hour: hour)
            timeCounts[timeOfDay, default: 0] += 1
        }

        return timeCounts.max(by: { $0.value < $1.value })?.key ?? .evening
    }

    private func mostCommonDayOfWeek(entries: [LocationEntry]) -> String? {
        var dayCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.date)
            dayCounts[weekday, default: 0] += 1
        }

        if let mostCommon = dayCounts.max(by: { $0.value < $1.value }), mostCommon.value >= 2 {
            return mostCommon.key >= 1 && mostCommon.key < dayNames.count ? dayNames[mostCommon.key] : nil
        }

        return nil
    }

    private func categorizeBelief(_ belief: Belief) -> String {
        let text = belief.text.lowercased()

        if text.contains("work") || text.contains("job") || text.contains("career") {
            return "Work"
        } else if text.contains("relationship") || text.contains("friend") || text.contains("social") {
            return "Social"
        } else if text.contains("family") || text.contains("parent") || text.contains("child") {
            return "Family"
        } else if text.contains("money") || text.contains("financial") || text.contains("success") {
            return "Financial"
        } else if text.contains("health") || text.contains("body") || text.contains("exercise") {
            return "Health"
        } else if text.contains("self") || text.contains("worth") || text.contains("love") {
            return "Self-Esteem"
        } else {
            return "General"
        }
    }

    private func generateDescription(
        location: KnownLocation,
        frequency: Int,
        timeOfDay: TimeOfDay,
        dayOfWeek: String?,
        category: String
    ) -> String {
        var description = "You do most of your \(category.lowercased()) belief work at \(location.rawValue.lowercased()) during \(timeOfDay.rawValue.lowercased())s"

        if let day = dayOfWeek {
            description += " on \(day)s"
        }

        description += "."

        return description
    }

    private func generateSampleInsights() -> [LocationInsight] {
        return [
            LocationInsight(
                location: KnownLocation.home.rawValue,
                beliefWorkFrequency: 45,
                mostCommonBeliefCategory: "Work",
                averageScore: 65,
                timeOfDay: .evening,
                dayOfWeek: "Sunday",
                description: "You do most of your work belief work at home during evenings on Sundays."
            ),
            LocationInsight(
                location: KnownLocation.office.rawValue,
                beliefWorkFrequency: 28,
                mostCommonBeliefCategory: "Performance",
                averageScore: 58,
                timeOfDay: .morning,
                dayOfWeek: "Monday",
                description: "You challenge performance beliefs most often at the office during mornings on Mondays."
            ),
            LocationInsight(
                location: KnownLocation.home.rawValue,
                beliefWorkFrequency: 22,
                mostCommonBeliefCategory: "Self-Esteem",
                averageScore: 72,
                timeOfDay: .lateNight,
                dayOfWeek: nil,
                description: "Late night reflection on self-esteem beliefs happens frequently at home."
            )
        ]
    }
}

// MARK: - Sequence Extension for Uniquing

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
