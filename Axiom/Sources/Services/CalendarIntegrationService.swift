import Foundation
#if os(macOS)
import EventKit
#endif

/// R23: Calendar integration for AxiomMac
/// Detects events that might trigger belief challenges
/// e.g., "You usually challenge your performance beliefs after big meetings"

@MainActor
final class CalendarIntegrationService: @unchecked Sendable {
    static let shared = CalendarIntegrationService()

    // MARK: - Types

    struct CalendarInsight: Identifiable {
        let id = UUID()
        let trigger: String
        let beliefPatterns: [String]
        let frequency: Int
        let category: InsightCategory
    }

    enum InsightCategory: String, Codable {
        case work = "Work"
        case social = "Social"
        case personal = "Personal"
        case health = "Health"
        case general = "General"
    }

    // MARK: - Public Methods

    /// Detect calendar patterns and link them to belief work
    @MainActor
    func detectCalendarPatterns(events: [Event]) -> [CalendarInsight] {
        guard events.count >= 5 else { return [] }

        let beliefs = DatabaseService.shared.allBeliefs
        var insights: [CalendarInsight] = []

        // Analyze meeting patterns
        if let meetingInsight = analyzeMeetingPatterns(events: events, beliefs: beliefs) {
            insights.append(meetingInsight)
        }

        // Analyze presentation patterns
        if let presentationInsight = analyzePresentationPatterns(events: events) {
            insights.append(presentationInsight)
        }

        // Analyze deadline patterns
        if let deadlineInsight = analyzeDeadlinePatterns(events: events) {
            insights.append(deadlineInsight)
        }

        // Analyze social patterns
        if let socialInsight = analyzeSocialPatterns(events: events) {
            insights.append(socialInsight)
        }

        // Analyze exercise patterns
        if let exerciseInsight = analyzeExercisePatterns(events: events) {
            insights.append(exerciseInsight)
        }

        return insights
    }

    /// Fetch events from the system calendar
    @MainActor
    func fetchEvents(from startDate: Date, to endDate: Date) async -> [Event] {
        #if os(macOS)
        let authStatus = await requestCalendarAccess()
        guard authStatus else {
            return generateSampleEvents(from: startDate, to: endDate)
        }

        let store = EKEventStore()
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        return ekEvents.map { ekEvent in
            Event(
                id: ekEvent.eventIdentifier ?? UUID().uuidString,
                title: ekEvent.title ?? "Untitled",
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                isAllDay: ekEvent.isAllDay,
                calendar: ekEvent.calendar?.title ?? "Unknown",
                notes: ekEvent.notes,
                location: ekEvent.location
            )
        }
        #else
        return generateSampleEvents(from: startDate, to: endDate)
        #endif
    }

    #if os(macOS)
    @MainActor
    private func requestCalendarAccess() async -> Bool {
        let store = EKEventStore()
        if #available(macOS 14.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            do {
                return try await store.requestAccess(to: .event)
            } catch {
                return false
            }
        }
    }
    #endif

    // MARK: - Private Methods

    private func analyzeMeetingPatterns(events: [Event], beliefs: [Belief]) -> CalendarInsight? {
        let meetings = events.filter { event in
            event.title.lowercased().contains("meeting") ||
            event.title.lowercased().contains("sync") ||
            event.title.lowercased().contains("standup") ||
            event.title.lowercased().contains("1:1") ||
            event.title.lowercased().contains("1:1s")
        }

        guard meetings.count >= 3 else { return nil }

        // Count meetings by day of week
        var dayFrequency: [Int: Int] = [:]
        let calendar = Calendar.current

        for meeting in meetings {
            let weekday = calendar.component(.weekday, from: meeting.startDate)
            dayFrequency[weekday, default: 0] += 1
        }

        // Find most common day
        let mostCommonDay = dayFrequency.max(by: { $0.value < $1.value })?.key
        let dayName = mostCommonDay.map { weekdayName($0) } ?? "weekday"

        let beliefPatterns = extractBeliefPatterns(from: beliefs, relatedTo: .work)

        return CalendarInsight(
            trigger: "After \(meetings.count) meetings on \(dayName)s",
            beliefPatterns: beliefPatterns,
            frequency: meetings.count,
            category: .work
        )
    }

    private func analyzePresentationPatterns(events: [Event]) -> CalendarInsight? {
        let presentations = events.filter { event in
            event.title.lowercased().contains("presentation") ||
            event.title.lowercased().contains("demo") ||
            event.title.lowercased().contains("pitch") ||
            event.title.lowercased().contains("talk") ||
            event.title.lowercased().contains("webinar")
        }

        guard presentations.count >= 2 else { return nil }

        let beliefPatterns = [
            "Performance beliefs",
            "Competence beliefs"
        ]

        return CalendarInsight(
            trigger: "Around presentations and demos",
            beliefPatterns: beliefPatterns,
            frequency: presentations.count,
            category: .work
        )
    }

    private func analyzeDeadlinePatterns(events: [Event]) -> CalendarInsight? {
        let deadlines = events.filter { event in
            event.title.lowercased().contains("deadline") ||
            event.title.lowercased().contains("due") ||
            event.title.lowercased().contains("submit") ||
            event.title.lowercased().contains("launch")
        }

        guard deadlines.count >= 3 else { return nil }

        let beliefPatterns = [
            "Achievement beliefs",
            "Capability beliefs"
        ]

        return CalendarInsight(
            trigger: "Near project deadlines",
            beliefPatterns: beliefPatterns,
            frequency: deadlines.count,
            category: .work
        )
    }

    private func analyzeSocialPatterns(events: [Event]) -> CalendarInsight? {
        let socialEvents = events.filter { event in
            event.title.lowercased().contains("dinner") ||
            event.title.lowercased().contains("party") ||
            event.title.lowercased().contains("birthday") ||
            event.title.lowercased().contains("social") ||
            event.title.lowercased().contains("coffee")
        }

        guard socialEvents.count >= 2 else { return nil }

        let beliefPatterns = [
            "Social comparison beliefs",
            "Relationship beliefs"
        ]

        return CalendarInsight(
            trigger: "After social events",
            beliefPatterns: beliefPatterns,
            frequency: socialEvents.count,
            category: .social
        )
    }

    private func analyzeExercisePatterns(events: [Event]) -> CalendarInsight? {
        let exerciseEvents = events.filter { event in
            event.title.lowercased().contains("gym") ||
            event.title.lowercased().contains("run") ||
            event.title.lowercased().contains("workout") ||
            event.title.lowercased().contains("yoga") ||
            event.title.lowercased().contains("sport")
        }

        guard exerciseEvents.count >= 3 else { return nil }

        let beliefPatterns = [
            "Physical capability beliefs",
            "Self-care beliefs"
        ]

        return CalendarInsight(
            trigger: "After exercise sessions",
            beliefPatterns: beliefPatterns,
            frequency: exerciseEvents.count,
            category: .health
        )
    }

    private nonisolated func extractBeliefPatterns(from beliefs: [Belief], relatedTo category: InsightCategory) -> [String] {
        switch category {
        case .work:
            let workBeliefs = beliefs.filter {
                $0.text.lowercased().contains("work") ||
                $0.text.lowercased().contains("performance") ||
                $0.text.lowercased().contains("competent") ||
                $0.text.lowercased().contains("capable")
            }
            return Array(workBeliefs.prefix(3).map { $0.text })

        case .social:
            let socialBeliefs = beliefs.filter {
                $0.text.lowercased().contains("people") ||
                $0.text.lowercased().contains("social") ||
                $0.text.lowercased().contains("friend")
            }
            return Array(socialBeliefs.prefix(3).map { $0.text })

        case .personal:
            return Array(beliefs.prefix(3).map { $0.text })

        case .health, .general:
            return []
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[safe: weekday] ?? "weekday"
    }

    private func generateSampleEvents(from startDate: Date, to endDate: Date) -> [Event] {
        var events: [Event] = []
        let calendar = Calendar.current

        // Generate sample meeting events
        var currentDate = startDate
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)

            // Add meetings on weekdays
            if weekday >= 2 && weekday <= 6 {
                let hour = [9, 10, 14, 15][Int.random(in: 0..<4)]
                if let meetingTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: currentDate) {
                    events.append(Event(
                        id: UUID().uuidString,
                        title: "Team Meeting",
                        startDate: meetingTime,
                        endDate: calendar.date(byAdding: .hour, value: 1, to: meetingTime) ?? meetingTime,
                        isAllDay: false,
                        calendar: "Work",
                        notes: nil,
                        location: "Conference Room"
                    ))
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }

        return events
    }
}

// MARK: - Supporting Types

struct Event: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendar: String
    let notes: String?
    let location: String?
}


