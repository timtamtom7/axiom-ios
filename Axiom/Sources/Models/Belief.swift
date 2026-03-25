import Foundation

struct Belief: Identifiable, Equatable, Hashable {
    let id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var evidenceItems: [Evidence]
    var isCore: Bool // Core beliefs are foundational
    var rootCause: String? // e.g. "Childhood experience", "Trauma", "Cultural programming"
    var derivedFrom: UUID? // ID of parent belief if this is a chain
    var checkInScheduledAt: Date?
    var checkInIntervalDays: Int? // 30, 60, or 90
    var isArchived: Bool
    var archivedAt: Date?
    var archiveReason: String?
    var archivedScore: Double?

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        evidenceItems: [Evidence] = [],
        isCore: Bool = false,
        rootCause: String? = nil,
        derivedFrom: UUID? = nil,
        checkInScheduledAt: Date? = nil,
        checkInIntervalDays: Int? = nil,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        archiveReason: String? = nil,
        archivedScore: Double? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.evidenceItems = evidenceItems
        self.isCore = isCore
        self.rootCause = rootCause
        self.derivedFrom = derivedFrom
        self.checkInScheduledAt = checkInScheduledAt
        self.checkInIntervalDays = checkInIntervalDays
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.archiveReason = archiveReason
        self.archivedScore = archivedScore
    }

    var supportingCount: Int {
        evidenceItems.filter { $0.type == .support }.count
    }

    var contradictingCount: Int {
        evidenceItems.filter { $0.type == .contradict }.count
    }

    var score: Double {
        let sup = Double(supportingCount)
        let con = Double(contradictingCount)
        return (sup + 1) / (sup + con + 2) * 100
    }

    var scoreCategory: ScoreCategory {
        if score < 40 {
            return .low
        } else if score < 70 {
            return .medium
        } else {
            return .high
        }
    }

    var connections: [BeliefConnection] {
        // Connections are stored in DatabaseService
        []
    }

    mutating func scheduleCheckIn(days: Int) {
        checkInIntervalDays = days
        checkInScheduledAt = Calendar.current.date(byAdding: .day, value: days, to: Date())
        updatedAt = Date()
    }
}

enum ScoreCategory {
    case low, medium, high
}

extension Belief {
    static let preview = Belief(
        text: "I am bad at relationships",
        evidenceItems: [
            Evidence(beliefId: UUID(), text: "My last relationship ended badly", type: .support, confidence: 0.8),
            Evidence(beliefId: UUID(), text: "I have many close friends who value me", type: .contradict, confidence: 0.9)
        ]
    )
}
