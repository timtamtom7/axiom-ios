import Foundation

struct Belief: Identifiable, Equatable, Hashable {
    let id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var evidenceItems: [Evidence]

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), updatedAt: Date = Date(), evidenceItems: [Evidence] = []) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.evidenceItems = evidenceItems
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

    mutating func updateScore() {
        // Score is computed property; updatedAt tracks last evidence change
    }
}

enum ScoreCategory {
    case low, medium, high
}

extension Belief {
    static let preview = Belief(
        text: "I am bad at relationships",
        evidenceItems: [
            Evidence(beliefId: UUID(), text: "My last relationship ended badly", type: .support),
            Evidence(beliefId: UUID(), text: "I have many close friends who value me", type: .contradict)
        ]
    )
}
