import Foundation
import NaturalLanguage

// MARK: - Detected Distortion

struct DetectedDistortion: Identifiable {
    let id = UUID()
    let type: CognitiveDistortion
    let matchedPhrase: String
    let context: String
    let socraticChallenge: String
    let severity: Severity

    enum Severity: String, Codable {
        case mild, moderate, strong
        var color: String {
            switch self {
            case .mild:     return "FFCA28"
            case .moderate: return "42A5F5"
            case .strong:   return "EF5350"
            }
        }
    }
}

// MARK: - Belief Analysis

struct BeliefAnalysis: Identifiable, Codable {
    let id: UUID
    let belief: String
    let score: Double
    let distortions: [CognitiveDistortion]
    let healthierAlternative: String
    let challengeQuestions: [String]
    let date: Date
}

// MARK: - Sentiment Result

struct SentimentResult: Identifiable {
    let id = UUID()
    let score: Double
    let label: String
}

// MARK: - Pattern Result

struct PatternResult: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let description: String
    let color: String
    let type: CognitiveDistortion
}

// MARK: - AIBeliefService

final class AIBeliefService: ObservableObject, @unchecked Sendable {
    static let shared = AIBeliefService()

    func detectDistortions(in text: String) -> [CognitiveDistortion] {
        var detected: [CognitiveDistortion] = []
        let lower = text.lowercased()
        if ["always", "never", "completely", "totally", "entirely", "perfect", "terrible", "worst", "best"].contains(where: { lower.contains($0) }) {
            detected.append(.allOrNothing)
        }
        if ["everything", "nothing", "everyone", "no one"].contains(where: { lower.contains($0) }) {
            detected.append(.overgeneralization)
        }
        if lower.contains("should") || lower.contains("must") {
            detected.append(.shouldStatements)
        }
        if lower.contains("worthless") || lower.contains("failure") || lower.contains("loser") {
            detected.append(.labeling)
        }
        return detected
    }

    func analyzeSentiment(of text: String) -> SentimentResult {
        let lower = text.lowercased()
        let pos = ["good", "great", "happy", "love", "excellent", "wonderful", "better", "best"].filter { lower.contains($0) }.count
        let neg = ["bad", "terrible", "hate", "awful", "worse", "worst", "sad", "angry"].filter { lower.contains($0) }.count
        let total = Double(max(pos + neg, 1))
        let score = Double(pos - neg) / total
        return SentimentResult(score: score, label: score > 0.2 ? "positive" : score < -0.2 ? "negative" : "neutral")
    }

    func detectPatternsAcrossBeliefs(_ beliefs: [Belief]) -> [PatternResult] {
        return []
    }

    func analyzeBelief(_ belief: Belief) -> BeliefAnalysis {
        let distortions = detectDistortions(in: belief.text)
        let sentiment = analyzeSentiment(of: belief.text)
        let questions = distortions.map { $0.gentleQuestion }
        return BeliefAnalysis(
            id: belief.id,
            belief: belief.text,
            score: sentiment.score * 100,
            distortions: distortions,
            healthierAlternative: distortions.isEmpty ? "Balanced thinking." : distortions.first?.description ?? "Consider other perspectives.",
            challengeQuestions: Array(questions.prefix(4) + ["What evidence supports this belief? What contradicts it?"]),
            date: belief.createdAt
        )
    }

    func analyzeAllBeliefs(_ beliefs: [Belief]) -> [UUID: BeliefAnalysis] {
        var results: [UUID: BeliefAnalysis] = [:]
        for belief in beliefs {
            results[belief.id] = analyzeBelief(belief)
        }
        return results
    }

    func distortionSummary(for beliefs: [Belief]) -> [(CognitiveDistortion, Int, String)] {
        var counts: [CognitiveDistortion: Int] = [:]
        for belief in beliefs {
            let distortions = detectDistortions(in: belief.text)
            for distortion in distortions {
                counts[distortion, default: 0] += 1
            }
        }
        return counts.map { ($0.key, $0.value, $0.key.gentleQuestion) }.sorted { $0.1 > $1.1 }
    }
}
