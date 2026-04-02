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

/// Cognitive distortion types for CBT-based belief analysis
enum CognitiveDistortion: String, Codable, CaseIterable {
    case allOrNothing          = "All-or-Nothing Thinking"
    case catastrophizing       = "Catastrophizing"
    case mindReading           = "Mind Reading"
    case fortuneTelling        = "Fortune Telling"
    case emotionalReasoning    = "Emotional Reasoning"
    case shouldStatements      = "Should Statements"
    case labeling              = "Labeling"
    case magnification         = "Magnification/Minimization"
    case overgeneralization    = "Overgeneralization"
    case personalization       = "Personalization"
    case mentalFilter          = "Mental Filter"
    case discounting           = "Discounting the Positive"

    var description: String {
        switch self {
        case .allOrNothing:       return "Seeing things in black and white categories"
        case .catastrophizing:    return "Expecting the worst possible outcome"
        case .mindReading:        return "Assuming you know what others think"
        case .fortuneTelling:     return "Predicting things will go badly"
        case .emotionalReasoning: return "Believing feelings reflect reality"
        case .shouldStatements:   return "Using 'should' or 'must' demands"
        case .labeling:           return "Attaching negative labels to yourself"
        case .magnification:      return "Blowing things out of proportion"
        case .overgeneralization: return "Making broad conclusions from single events"
        case .personalization:    return "Taking blame for external events"
        case .mentalFilter:       return "Focusing only on negatives"
        case .discounting:        return "Rejecting positive experiences"
        }
    }

    var gentleQuestion: String {
        switch self {
        case .allOrNothing:
            return "Is there a middle ground between these two extremes?"
        case .catastrophizing:
            return "What's the most likely outcome, not the worst?"
        case .mindReading:
            return "What evidence do you have that they actually think that?"
        case .fortuneTelling:
            return "What evidence suggests this prediction will come true?"
        case .emotionalReasoning:
            return "Just because you feel it, does that make it true?"
        case .shouldStatements:
            return "What if you replaced 'should' with 'could'?"
        case .labeling:
            return "Is this label accurate, or is it an oversimplification?"
        case .magnification:
            return "Are you giving this appropriate weight?"
        case .overgeneralization:
            return "Does this single event really define the pattern?"
        case .personalization:
            return "What other factors might have contributed?"
        case .mentalFilter:
            return "What positives might you be overlooking?"
        case .discounting:
            return "Why might these positive experiences still count?"
        }
    }
}

enum ScoreLevel {
    case low, medium, high
    init(score: Double) {
        if score < 40 { self = .low }
        else if score <= 70 { self = .medium }
        else { self = .high }
    }
}

struct CommunityPost: Identifiable, Equatable {
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


