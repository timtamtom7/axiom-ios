import Foundation
import NaturalLanguage

/// R11: AI-powered belief analysis and cognitive restructuring
final class AIBeliefService {
    static let shared = AIBeliefService()

    private let tagger: NLTagger

    private init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType])
    }

    // MARK: - Main Analysis

    /// Analyze a belief and identify cognitive distortions
    func analyzeBelief(_ belief: Belief) -> BeliefAnalysis {
        let text = belief.text.lowercased()
        let distortions = detectDistortions(in: text)
        let questions = generateChallengeQuestions(for: belief, distortions: distortions)
        let alternative = generateAlternativeBelief(for: belief, distortions: distortions)
        let confidence = calculateConfidence(distortions: distortions, belief: belief)

        return BeliefAnalysis(
            distortions: distortions,
            challengeQuestions: questions,
            alternativeBelief: alternative,
            confidenceScore: confidence
        )
    }

    // MARK: - Distortion Detection

    private func detectDistortions(in text: String) -> [CognitiveDistortion] {
        var detected: [CognitiveDistortion] = []
        let lower = text.lowercased()

        // All-or-Nothing: words like "always", "never", "completely", "totally", "entirely"
        let allOrNothingPatterns = ["always", "never", "completely", "totally", "entirely", "perfect", "terrible", "worst", "best"]
        if allOrNothingPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.allOrNothing)
        }

        // Catastrophizing: "disaster", "ruined", "unbearable", "horrible", "can't stand"
        let catastrophePatterns = ["disaster", "ruined", "unbearable", "horrible", "can't stand", "end of the world", "unbearable"]
        if catastrophePatterns.contains(where: { lower.contains($0) }) {
            detected.append(.catastrophizing)
        }

        // Mind Reading: "they think", "she thinks", "he thinks", "everyone thinks", "they must think"
        let mindReadingPatterns = ["they think", "she thinks", "he thinks", "everyone thinks", "they must", "they probably", "she probably", "he probably"]
        if mindReadingPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.mindReading)
        }

        // Fortune Telling: "going to", "will never", "will always", "is going to", "won't be able to"
        let fortunePatterns = ["will never", "will always", "is going to", "won't be able", "going to be", "will fail", "will mess up", "is doomed"]
        if fortunePatterns.contains(where: { lower.contains($0) }) {
            detected.append(.fortuneTelling)
        }

        // Emotional Reasoning: "I feel like", "I feel that", "I feel so", "feels like"
        let emotionPatterns = ["i feel like", "i feel that", "i feel so", "it feels like", "i know i am", "i know they're"]
        if emotionPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.emotionalReasoning)
        }

        // Should Statements: "should", "shouldn't", "must", "have to", "ought to"
        let shouldPatterns = ["should", "shouldn't", "must ", "have to", "ought to", "i need to"]
        if shouldPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.shouldStatements)
        }

        // Labeling: "i am a", "i'm a", "he's a", "she's a" + negative labels
        let negativeLabels = ["failure", "loser", "idiot", "stupid", "worthless", "incompetent", "hopeless", "defective", "broken", "a mistake"]
        if negativeLabels.contains(where: { lower.contains($0) }) && (lower.contains("i am") || lower.contains("i'm") || lower.contains("i am")) {
            detected.append(.labeling)
        }

        // Overgeneralization: "everything", "nothing", "all the time", "every time"
        let overgenPatterns = ["everything", "nothing", "all the time", "every time", "nobody", "everybody"]
        if overgenPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.overgeneralization)
        }

        // Personalization: "it's my fault", "I caused", "I made them", "I made her", "I made him"
        let personalPatterns = ["it's my fault", "i caused", "i made them", "i made her", "i made him", "I made it happen"]
        if personalPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.personalization)
        }

        // Magnification: "so", "really", "very" + dramatic context
        if let range = lower.range(of: "so ") {
            let afterSo = lower[range.upperBound...]
            let dramatic = ["sad", "angry", "bad", "terrible", "depressed", "anxious", "scared"]
            if dramatic.contains(where: { afterSo.hasPrefix($0) }) {
                detected.append(.magnification)
            }
        }

        // Mental Filter: "can't stop thinking about", "all I see is", "only see"
        let filterPatterns = ["can't stop thinking", "all i see is", "only see", "nothing but", "focus on"]
        if filterPatterns.contains(where: { lower.contains($0) }) {
            detected.append(.mentalFilter)
        }

        // Discounting: "doesn't count", "that doesn't count", "but"
        if lower.contains("but") && (lower.contains("doesn't count") || lower.contains("not real") || lower.contains("doesn't matter")) {
            detected.append(.discounting)
        }

        return detected
    }

    // MARK: - Challenge Questions

    private func generateChallengeQuestions(for belief: Belief, distortions: [CognitiveDistortion]) -> [String] {
        var questions: [String] = []

        // Always add these foundational questions
        questions.append("What evidence supports this belief? What evidence contradicts it?")
        questions.append("If a friend came to me with this belief, what would I tell them?")

        // Add distortion-specific questions
        for distortion in distortions {
            questions.append(distortion.gentleQuestion)
        }

        // Context-aware questions
        if belief.score < 50 {
            questions.append("What would need to be true for this belief to be less absolute?")
            questions.append("Can you think of an exception to this belief?")
        }

        if belief.evidenceItems.isEmpty {
            questions.append("What evidence would you need to evaluate this belief properly?")
        } else {
            let supporting = belief.evidenceItems.filter { $0.type == .support }
            let contradicting = belief.evidenceItems.filter { $0.type == .contradict }
            if supporting.count > contradicting.count + 2 {
                questions.append("Are you weighting the supporting evidence more heavily than the contradicting evidence?")
            }
        }

        if belief.isCore {
            questions.append("Where did this core belief come from? Is it still serving you?")
        }

        return questions
    }

    // MARK: - Alternative Belief Generation

    private func generateAlternativeBelief(for belief: Belief, distortions: [CognitiveDistortion]) -> String {
        var alternative = belief.text

        // If no distortions detected, suggest a balanced reframe
        if distortions.isEmpty {
            return "This belief may be accurate, but worth examining the evidence again."
        }

        // Replace absolute language with nuanced language
        let replacements: [(String, String)] = [
            ("always", "sometimes"),
            ("never", "rarely"),
            ("completely", "partially"),
            ("totally", "somewhat"),
            ("terrible", "challenging"),
            ("horrible", "difficult"),
            ("worst", "most difficult"),
            ("everyone thinks", "some people might think"),
            ("I am a failure", "I made a mistake"),
            ("I am worthless", "I am doing my best"),
            ("I can't stand it", "I find this difficult"),
            ("will never", "may not"),
            ("is going to", "might"),
            ("should", "could"),
            ("must", "would like to"),
            ("I feel like I am", "I think I might be"),
        ]

        for (from, to) in replacements {
            if alternative.lowercased().contains(from) {
                alternative = alternative.replacingOccurrences(of: from, with: to, options: .caseInsensitive)
            }
        }

        // Add nuance based on evidence
        if belief.score < 40 {
            alternative = "It's possible that " + alternative.lowercased()
        } else if belief.score > 70 {
            alternative = "While " + alternative.lowercased() + ", I remain open to new evidence"
        } else {
            alternative = "I notice that " + alternative.lowercased() + " — and I'm learning to hold this more lightly"
        }

        return alternative.capitalizingFirstLetter()
    }

    // MARK: - Confidence Score

    private func calculateConfidence(distortions: [CognitiveDistortion], belief: Belief) -> Int {
        var confidence = 70 // Base confidence

        // More distortions = lower confidence in the analysis
        confidence -= distortions.count * 8

        // Strong evidence base increases confidence
        let evidenceCount = belief.evidenceItems.count
        if evidenceCount >= 5 {
            confidence += 15
        } else if evidenceCount >= 3 {
            confidence += 10
        } else if evidenceCount == 0 {
            confidence -= 15
        }

        // Low belief score + distortion = more confident detection
        if belief.score < 40 && !distortions.isEmpty {
            confidence += 10
        }

        // Core beliefs with distortions need more scrutiny
        if belief.isCore && distortions.contains(.allOrNothing) {
            confidence -= 5
        }

        return min(95, max(20, confidence))
    }

    // MARK: - Batch Analysis

    func analyzeAllBeliefs(_ beliefs: [Belief]) -> [UUID: BeliefAnalysis] {
        var results: [UUID: BeliefAnalysis] = [:]
        for belief in beliefs {
            results[belief.id] = analyzeBelief(belief)
        }
        return results
    }

    // MARK: - Distortion Summary

    func distortionSummary(for beliefs: [Belief]) -> [(CognitiveDistortion, Int)] {
        var counts: [CognitiveDistortion: Int] = [:]
        for belief in beliefs {
            let analysis = analyzeBelief(belief)
            for distortion in analysis.distortions {
                counts[distortion, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
    }
}

// MARK: - BeliefAnalysis

struct BeliefAnalysis: Identifiable {
    let id = UUID()
    let distortions: [CognitiveDistortion]
    let challengeQuestions: [String]
    let alternativeBelief: String
    let confidenceScore: Int

    var hasDistortions: Bool { !distortions.isEmpty }

    var summaryDescription: String {
        if distortions.isEmpty {
            return "No clear cognitive distortions detected in this belief."
        }
        if distortions.count == 1 {
            return "This belief shows signs of \(distortions[0].rawValue.lowercased())."
        }
        let names = distortions.prefix(2).map { $0.rawValue.lowercased() }.joined(separator: " and ")
        return "This belief shows signs of \(names)."
    }
}

// MARK: - String Extension

private extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}
