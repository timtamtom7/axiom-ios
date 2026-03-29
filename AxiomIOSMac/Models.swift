import Foundation

struct Belief: Identifiable, Codable {
    let id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var score: Double
    var isCore: Bool
    var evidenceItems: [Evidence]

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), updatedAt: Date = Date(), score: Double = 50, isCore: Bool = false, evidenceItems: [Evidence] = []) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.score = score
        self.isCore = isCore
        self.evidenceItems = evidenceItems
    }
}

struct Evidence: Identifiable, Codable {
    let id: UUID
    let beliefId: UUID
    var text: String
    var type: EvidenceType
    var createdAt: Date

    init(id: UUID = UUID(), beliefId: UUID, text: String, type: EvidenceType, createdAt: Date = Date()) {
        self.id = id
        self.beliefId = beliefId
        self.text = text
        self.type = type
        self.createdAt = createdAt
    }
}

enum EvidenceType: String, Codable {
    case support
    case contradict
}

enum ScoreLevel {
    case low, medium, high
    init(score: Double) {
        if score < 40 { self = .low }
        else if score <= 70 { self = .medium }
        else { self = .high }
    }
}

struct CommunityPost: Identifiable {
    let id: UUID
    let beliefText: String
    let postText: String
    let timestamp: Date
    let isAnonymous: Bool
    let upvotes: Int
    let comments: Int
}

struct InsightItem: Identifiable {
    let id: UUID
    let title: String
    let body: String
    let type: InsightType
    let date: Date
}

enum InsightType {
    case trajectory, weeklySynthesis, aiAnalysis, beliefPattern
}
