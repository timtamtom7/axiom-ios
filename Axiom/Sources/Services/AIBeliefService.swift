import Foundation
import NaturalLanguage

// MARK: - Cognitive Distortion Types (12 Types)

enum CognitiveDistortionType: String, CaseIterable, Codable, Identifiable {
    case allOrNothing          = "All-or-Nothing Thinking"
    case overgeneralization    = "Overgeneralization"
    case mentalFilter          = "Mental Filter"
    case disqualifyingPositive = "Disqualifying the Positive"
    case jumpingToConclusions   = "Jumping to Conclusions"
    case mindReading           = "Mind Reading"
    case fortuneTelling        = "Fortune Telling"
    case magnification         = "Magnification / Catastrophizing"
    case emotionalReasoning    = "Emotional Reasoning"
    case shouldStatements      = "Should Statements"
    case labeling              = "Labeling"
    case personalization       = "Personalization"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allOrNothing:          return "equal.square"
        case .overgeneralization:    return "arrow.triangle.branch"
        case .mentalFilter:          return "camera.filters"
        case .disqualifyingPositive: return "xmark.circle"
        case .jumpingToConclusions:  return "figure.walk"
        case .mindReading:           return "brain.head.profile"
        case .fortuneTelling:        return "crystal.ball"
        case .magnification:         return "exclamationmark.triangle"
        case .emotionalReasoning:    return "heart"
        case .shouldStatements:      return "text.badge.minus"
        case .labeling:              return "tag"
        case .personalization:       return "person.fill"
        }
    }

    var description: String {
        switch self {
        case .allOrNothing:          return "Seeing things in black and white, with no middle ground."
        case .overgeneralization:    return "Drawing sweeping conclusions from a single event."
        case .mentalFilter:          return "Focusing only on the negative details while ignoring the positive."
        case .disqualifyingPositive: return "Dismissing positive experiences as 'not counting'."
        case .jumpingToConclusions:  return "Making negative interpretations without evidence."
        case .mindReading:           return "Assuming you know what others are thinking without evidence."
        case .fortuneTelling:        return "Predicting things will go badly before they do."
        case .magnification:         return "Exaggerating negatives or minimizing positives."
        case .emotionalReasoning:    return "Believing feelings are facts — if you feel it, it must be true."
        case .shouldStatements:      return "Using 'should' and 'must' to create unrealistic standards."
        case .labeling:             return "Attaching a fixed, negative label to yourself or others."
        case .personalization:      return "Taking responsibility for things outside your control."
        }
    }

    var socraticChallenge: String {
        switch self {
        case .allOrNothing:
            return "Is there a way to see this situation with more nuance — something in between the extremes?"
        case .overgeneralization:
            return "What evidence suggests this is truly a pattern, not just a one-time event?"
        case .mentalFilter:
            return "What positive or neutral aspects of this situation might you be overlooking?"
        case .disqualifyingPositive:
            return "Why might this positive experience actually count as valid evidence?"
        case .jumpingToConclusions:
            return "What facts do you actually have? What other explanations are possible?"
        case .mindReading:
            return "How do you know what they really think? What evidence do you have?"
        case .fortuneTelling:
            return "What would you say to someone who was certain the opposite outcome would happen?"
        case .magnification:
            return "If a friend were in this situation, how would you help them see it proportionally?"
        case .emotionalReasoning:
            return "Just because something feels true doesn't mean it is. What's the actual evidence?"
        case .shouldStatements:
            return "Where does this 'should' come from? Is it a rule or a preference? Are there exceptions?"
        case .labeling:
            return "Is this label accurate and complete? Could you describe the behavior without the label?"
        case .personalization:
            return "What factors outside your control might have contributed to this outcome?"
        }
    }
}

// MARK: - Detected Distortion

struct DetectedDistortion: Identifiable {
    let id = UUID()
    let type: CognitiveDistortionType
    let matchedPhrase: String
    let context: String
    let socraticChallenge: String
    let severity: Severity

    enum Severity: String {
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

// MARK: - Sentiment Result

struct BeliefSentiment: Codable {
    let overall: SentimentPolarity
    let score: Double // -1.0 to 1.0
    let keywords: [String]
    let emotionalTone: EmotionalTone

    enum SentimentPolarity: String, Codable {
        case positive, negative, neutral
    }

    enum EmotionalTone: String, Codable {
        case hopeful, anxious, angry, sad, neutral, confident, fearful, ashamed
    }
}

// MARK: - AIBeliefService

@MainActor
final class AIBeliefService: ObservableObject {
    static let shared = AIBeliefService()

    private let tagger: NLTagger

    private init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType, .lexicalClass])
    }

    // MARK: - Sentiment Analysis

    func analyzeSentiment(of text: String) -> BeliefSentiment {
        let cleanText = text.lowercased()

        tagger.string = text
        var totalScore: Double = 0
        var count = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, range in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        let avgScore = count > 0 ? totalScore / Double(count) : 0

        let polarity: BeliefSentiment.SentimentPolarity
        if avgScore > 0.1 {
            polarity = .positive
        } else if avgScore < -0.1 {
            polarity = .negative
        } else {
            polarity = .neutral
        }

        let emotionalTone = detectEmotionalTone(in: cleanText)
        let keywords = extractEmotionalKeywords(from: cleanText)

        return BeliefSentiment(
            overall: polarity,
            score: avgScore,
            keywords: keywords,
            emotionalTone: emotionalTone
        )
    }

    private func detectEmotionalTone(in text: String) -> BeliefSentiment.EmotionalTone {
        let hopeful = ["can", "able", "capable", "learning", "growing", "potential", "hope", "will", "going to"]
        let anxious = ["worried", "afraid", "scared", "nervous", "anxious", "terrified", "fear", "panic"]
        let angry = ["angry", "furious", "hate", "resent", "bitter", "mad"]
        let sad = ["sad", "depressed", "hopeless", "worthless", "empty", "lonely"]
        let confident = ["certain", "sure", "know", "always", "never", "definitely"]
        let fearful = ["danger", "threat", "unsafe", "risk", "vulnerable"]
        let ashamed = ["ashamed", "embarrassed", "humiliated", "guilty", "blame"]

        if hopeful.contains(where: { text.contains($0) }) { return .hopeful }
        if anxious.contains(where: { text.contains($0) }) { return .anxious }
        if angry.contains(where: { text.contains($0) }) { return .angry }
        if sad.contains(where: { text.contains($0) }) { return .sad }
        if confident.contains(where: { text.contains($0) }) { return .confident }
        if fearful.contains(where: { text.contains($0) }) { return .fearful }
        if ashamed.contains(where: { text.contains($0) }) { return .ashamed }
        return .neutral
    }

    private func extractEmotionalKeywords(from text: String) -> [String] {
        tagger.string = text
        var keywords: [String] = []
        let sentimentWords = ["always", "never", "terrible", "awful", "horrible", "bad", "good", "great", "wonderful", "perfect", "impossible", "failed", "success", "worthless", "incompetent", "stupid", "dumb", "ugly", "beautiful", "smart", "dumb"]

        for word in sentimentWords {
            if text.contains(word) {
                keywords.append(word)
            }
        }

        return Array(Set(keywords)).prefix(5).map { $0 }
    }

    // MARK: - Cognitive Distortion Detection

    func detectDistortions(in text: String) -> [DetectedDistortion] {
        var detected: [DetectedDistortion] = []
        let lowercased = text.lowercased()

        // All-or-Nothing: "always", "never", "completely", "totally", "absolutely"
        let aonPatterns = ["always", "never", "completely", "totally", "absolutely", "every single"]
        for pattern in aonPatterns {
            if lowercased.contains(pattern) {
                let context = extractContext(around: pattern, in: text)
                detected.append(DetectedDistortion(
                    type: .allOrNothing,
                    matchedPhrase: pattern,
                    context: context,
                    socraticChallenge: CognitiveDistortionType.allOrNothing.socraticChallenge,
                    severity: .strong
                ))
                break
            }
        }

        // Overgeneralization: single examples used as universal proof
        let ogPatterns = ["this proves", "shows i always", "just like everyone", "same as before", "so it will always"]
        for pattern in ogPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .overgeneralization,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.overgeneralization.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        // Mental Filter: focusing on negatives, "can't stop thinking about"
        let mfPatterns = ["can't stop thinking", "all i see is", "only see the", "focusing on how", "ruined", "ruins everything"]
        for pattern in mfPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .mentalFilter,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.mentalFilter.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        // Disqualifying the Positive: "but...", "doesn't count", "that doesn't mean"
        let dpPatterns = ["but that doesn't", "but i", "doesn't count", "anyone could", "that's just luck"]
        for pattern in dpPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .disqualifyingPositive,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.disqualifyingPositive.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        // Jumping to Conclusions / Mind Reading: "they think", "they believe", "he must think"
        let mrPatterns = ["they think i", "they believe", "he thinks", "she thinks", "they must think", "everyone thinks"]
        for pattern in mrPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .mindReading,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.mindReading.socraticChallenge,
                    severity: .strong
                ))
                break
            }
        }

        // Fortune Telling: "will fail", "going to", "is going to", "will never", "will always"
        let ftPatterns = ["will fail", "will never", "is going to", "going to be", "will definitely", "i'm sure it will"]
        for pattern in ftPatterns {
            if lowercased.contains(pattern) && !pattern.contains("going to") {
                detected.append(DetectedDistortion(
                    type: .fortuneTelling,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.fortuneTelling.socraticChallenge,
                    severity: .strong
                ))
                break
            }
        }
        if lowercased.contains("going to fail") || lowercased.contains("going to be bad") {
            detected.append(DetectedDistortion(
                type: .fortuneTelling,
                matchedPhrase: "going to",
                context: "Predicting a negative future outcome",
                socraticChallenge: CognitiveDistortionType.fortuneTelling.socraticChallenge,
                severity: .strong
            ))
        }

        // Magnification / Catastrophizing: "terrible", "horrible", "awful", "worst", "catastrophe"
        let magPatterns = ["terrible", "horrible", "awful", "worst", "catastroph", "the end", "unbearable", "devastating"]
        for pattern in magPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .magnification,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.magnification.socraticChallenge,
                    severity: .strong
                ))
                break
            }
        }

        // Emotional Reasoning: "i feel like", "i feel that", "i feel so"
        let erPatterns = ["i feel like", "i feel that", "i feel so", "i just feel", "feels like i am"]
        for pattern in erPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .emotionalReasoning,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.emotionalReasoning.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        // Should Statements: "should have", "shouldn't have", "must", "i should", "i shouldn't"
        let shouldPatterns = ["i should", "i shouldn't", "i must", "i must not", "should have", "shouldn't have", "ought to"]
        for pattern in shouldPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .shouldStatements,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.shouldStatements.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        // Labeling: "i'm a", "he's a", "she's a", followed by a negative label
        let negativeLabels = ["failure", "loser", "idiot", "stupid", "worthless", "hopeless", "incompetent", "jerk", "disaster"]
        for label in negativeLabels {
            if lowercased.contains("i'm a \(label)") || lowercased.contains("i am a \(label)") || lowercased.contains("i'm an \(label)") {
                detected.append(DetectedDistortion(
                    type: .labeling,
                    matchedPhrase: "a \(label)",
                    context: "Labeling yourself as \(label)",
                    socraticChallenge: CognitiveDistortionType.labeling.socraticChallenge,
                    severity: .strong
                ))
                break
            }
        }

        // Personalization: "i made", "it's my fault", "because of me", "i caused"
        let persPatterns = ["it's my fault", "i made this", "because of me", "i caused", "i'm the reason", "i ruined"]
        for pattern in persPatterns {
            if lowercased.contains(pattern) {
                detected.append(DetectedDistortion(
                    type: .personalization,
                    matchedPhrase: pattern,
                    context: extractContext(around: pattern, in: text),
                    socraticChallenge: CognitiveDistortionType.personalization.socraticChallenge,
                    severity: .moderate
                ))
                break
            }
        }

        return deduplicateAndRank(detected)
    }

    private func extractContext(around phrase: String, in text: String, window: Int = 40) -> String {
        let lowercased = text.lowercased()
        guard let phraseRange = lowercased.range(of: phrase.lowercased()) else {
            return String(text.prefix(80))
        }
        let start = text.index(phraseRange.lowerBound, offsetBy: -window, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(phraseRange.upperBound, offsetBy: window, limitedBy: text.endIndex) ?? text.endIndex
        var context = String(text[start..<end])
        if start != text.startIndex { context = "..." + context }
        if end != text.endIndex { context = context + "..." }
        return context.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    private func deduplicateAndRank(_ distortions: [DetectedDistortion]) -> [DetectedDistortion] {
        var seen: Set<CognitiveDistortionType> = []
        return distortions.filter { distortion in
            guard !seen.contains(distortion.type) else { return false }
            seen.insert(distortion.type)
            return true
        }.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }

    // MARK: - Socratic Challenge Questions

    func generateSocraticQuestions(for belief: Belief) -> [SocraticQuestion] {
        var questions: [SocraticQuestion] = []
        let distortions = detectDistortions(in: belief.text)

        // Add distortion-specific challenges
        for distortion in distortions.prefix(3) {
            questions.append(SocraticQuestion(
                id: UUID(),
                category: .cognitiveDistortion(distortion.type),
                question: distortion.socraticChallenge,
                followUps: generateFollowUps(for: distortion.type, belief: belief)
            ))
        }

        // Add general Socratic questions
        let generalQuestions: [SocraticQuestion] = [
            SocraticQuestion(
                id: UUID(),
                category: .evidence,
                question: "What is the most compelling piece of evidence that supports this belief?",
                followUps: [
                    "Is this evidence factual or interpreted?",
                    "Who provided this evidence, and what was their perspective?",
                    "Has this evidence been verified independently?"
                ]
            ),
            SocraticQuestion(
                id: UUID(),
                category: .perspective,
                question: "What would someone who loves and supports you say about this belief?",
                followUps: [
                    "Why might they see it differently?",
                    "What information do they have that you might be missing?",
                    "Would you accept this evidence if it came from a friend?"
                ]
            ),
            SocraticQuestion(
                id: UUID(),
                category: .alternative,
                question: "Is it possible that this belief is only true in certain situations, rather than always?",
                followUps: [
                    "What would an alternative belief sound like?",
                    "What would change if you adopted that alternative?",
                    "Have there been moments when a different belief felt truer?"
                ]
            ),
            SocraticQuestion(
                id: UUID(),
                category: .impact,
                question: "How does holding this belief serve you — even if it's uncomfortable?",
                followUps: [
                    "What would happen if you released this belief, even temporarily?",
                    "Is the belief protecting you from something?",
                    "What's the cost of maintaining this belief?"
                ]
            )
        ]

        questions.append(contentsOf: generalQuestions.prefix(4))
        return questions.shuffled()
    }

    private func generateFollowUps(for distortion: CognitiveDistortionType, belief: Belief) -> [String] {
        switch distortion {
        case .allOrNothing:
            return [
                "What would a 'gray area' version of this belief look like?",
                "Can you identify exceptions to this absolute statement?",
                "What middle ground feels more accurate?"
            ]
        case .overgeneralization:
            return [
                "What's the specific evidence for this pattern?",
                "Are there counterexamples to this pattern?",
                "What would need to be true for this to not be a pattern?"
            ]
        case .mentalFilter:
            return [
                "What positive aspects are being overlooked?",
                "If you were helping a friend, how would you describe this?",
                "What would you need to see to have a more balanced view?"
            ]
        case .disqualifyingPositive:
            return [
                "Why might this positive thing actually count?",
                "Who decides what 'counts' as evidence?",
                "If your best friend achieved this, would you dismiss it?"
            ]
        case .mindReading:
            return [
                "How do you know what they really think?",
                "Have you asked them directly?",
                "What evidence, aside from assumption, supports this?"
            ]
        case .fortuneTelling:
            return [
                "What evidence suggests this prediction will definitely come true?",
                "What's the best possible outcome you're not considering?",
                "Have you been wrong about predictions like this before?"
            ]
        case .magnification:
            return [
                "If a friend were in this situation, how would you help them see it?",
                "What would this look like in proportion to your whole life?",
                "What's the actual worst-case vs. most likely outcome?"
            ]
        case .emotionalReasoning:
            return [
                "What's the difference between how you feel and what's actually true?",
                "Have you ever felt something strongly that turned out to be inaccurate?",
                "If you didn't feel this way, what would you believe instead?"
            ]
        case .shouldStatements:
            return [
                "Where does this 'should' come from — you, or someone else?",
                "Are there legitimate exceptions to this rule?",
                "What would happen if you replaced 'should' with 'prefer'?"
            ]
        case .labeling:
            return [
                "Is this label an accurate and complete description of who you are?",
                "Can you separate the behavior from the person?",
                "What would you say to a child who labeled themselves this way?"
            ]
        case .personalization:
            return [
                "What other factors might have contributed?",
                "Are you taking responsibility for things outside your control?",
                "What would you tell a friend who blamed themselves this way?"
            ]
        case .jumpingToConclusions:
            return [
                "What facts do you have vs. interpretations?",
                "What other conclusions could fit the evidence?",
                "What would you need to see to feel more certain?"
            ]
        }
    }

    // MARK: - Pattern Detection Across Beliefs

    func detectPatternsAcrossBeliefs(_ beliefs: [Belief]) -> [BeliefPattern] {
        var patterns: [BeliefPattern] = []

        // Theme detection via keyword clustering
        let themePatterns = detectThemePatterns(in: beliefs)
        patterns.append(contentsOf: themePatterns)

        // Confidence-level patterns
        let confidencePatterns = detectConfidencePatterns(in: beliefs)
        patterns.append(contentsOf: confidencePatterns)

        // Cross-belief contradictions
        let contradictionPatterns = detectCrossBeliefContradictions(in: beliefs)
        patterns.append(contentsOf: contradictionPatterns)

        // Evolution patterns
        let evolutionPatterns = detectEvolutionPatterns(in: beliefs)
        patterns.append(contentsOf: evolutionPatterns)

        return patterns
    }

    private func detectThemePatterns(in beliefs: [Belief]) -> [BeliefPattern] {
        var patterns: [BeliefPattern] = []

        let themes: [(name: String, keywords: [String])] = [
            ("Relationships", ["relationship", "friend", "love", "partner", "social", "people", "family", "romantic"]),
            ("Self-Worth", ["worthy", "enough", "value", "deserve", "competent", "capable", "success", "failure"]),
            ("Control", ["control", "responsible", "power", "choice", "agency", "able", "can't", "must"]),
            ("Future", ["will", "going to", "future", "tomorrow", "never", "always", "predict"])
        ]

        for theme in themes {
            let matchingBeliefs = beliefs.filter { belief in
                theme.keywords.contains { keyword in
                    belief.text.lowercased().contains(keyword)
                }
            }
            if matchingBeliefs.count >= 2 {
                patterns.append(BeliefPattern(
                    id: UUID(),
                    title: "\(theme.name) Cluster",
                    description: "You have \(matchingBeliefs.count) beliefs related to \(theme.name.lowercased()). These may be interconnected.",
                    type: .theme,
                    affectedBeliefIds: matchingBeliefs.map(\.id),
                    icon: themeIcon(for: theme.name),
                    color: themeColor(for: theme.name)
                ))
            }
        }

        return patterns
    }

    private func detectConfidencePatterns(in beliefs: [Belief]) -> [BeliefPattern] {
        var patterns: [BeliefPattern] = []

        let lowConfidence = beliefs.filter { $0.scoreCategory == .low }
        if lowConfidence.count >= 3 {
            patterns.append(BeliefPattern(
                id: UUID(),
                title: "Multiple Low-Confidence Beliefs",
                description: "You have \(lowConfidence.count) beliefs with low evidence scores. These are ripe for deeper examination.",
                type: .confidence,
                affectedBeliefIds: lowConfidence.map(\.id),
                icon: "exclamationmark.triangle",
                color: "EF5350"
            ))
        }

        let highConfidence = beliefs.filter { $0.scoreCategory == .high }
        if highConfidence.count >= 3 {
            patterns.append(BeliefPattern(
                id: UUID(),
                title: "Strong Beliefs",
                description: "You have \(highConfidence.count) well-supported beliefs. Ensure you're not avoiding contradicting evidence.",
                type: .confidence,
                affectedBeliefIds: highConfidence.map(\.id),
                icon: "checkmark.seal",
                color: "4CAF50"
            ))
        }

        return patterns
    }

    private func detectCrossBeliefContradictions(in beliefs: [Belief]) -> [BeliefPattern] {
        var patterns: [BeliefPattern] = []

        for i in 0..<beliefs.count {
            for j in (i+1)..<beliefs.count {
                let b1 = beliefs[i].text.lowercased()
                let b2 = beliefs[j].text.lowercased()

                // Direct contradictions
                if (b1.contains("not") && !b2.contains("not") && b1.replacingOccurrences(of: "not", with: "") == b2) ||
                   (b2.contains("not") && !b1.contains("not") && b2.replacingOccurrences(of: "not", with: "") == b1) {
                    patterns.append(BeliefPattern(
                        id: UUID(),
                        title: "Contradictory Beliefs",
                        description: "'\(beliefs[i].text.prefix(30))...' and '\(beliefs[j].text.prefix(30))...' appear to contradict each other.",
                        type: .contradiction,
                        affectedBeliefIds: [beliefs[i].id, beliefs[j].id],
                        icon: "arrow.triangle.branch",
                        color: "FFCA28"
                    ))
                }

                // Same topic, different conclusions
                let sharedWords = Set(b1.split(separator: " ").map(String.init)).intersection(Set(b2.split(separator: " ").map(String.init)))
                if sharedWords.count >= 2 && abs(beliefs[i].score - beliefs[j].score) > 30 {
                    patterns.append(BeliefPattern(
                        id: UUID(),
                        title: "Same Topic, Different Conclusions",
                        description: "'\(beliefs[i].text.prefix(25))' and '\(beliefs[j].text.prefix(25))' share themes but have very different evidence levels.",
                        type: .contradiction,
                        affectedBeliefIds: [beliefs[i].id, beliefs[j].id],
                        icon: "scale.3d",
                        color: "42A5F5"
                    ))
                }
            }
        }

        return patterns
    }

    private func detectEvolutionPatterns(in beliefs: [Belief]) -> [BeliefPattern] {
        var patterns: [BeliefPattern] = []

        let beliefsWithHistory = beliefs.filter { $0.scoreHistory.count >= 3 }
        for belief in beliefsWithHistory {
            let history = belief.scoreHistory.sorted { $0.date < $1.date }
            guard let first = history.first, let last = history.last else { continue }
            let delta = last.score - first.score

            if delta > 25 {
                patterns.append(BeliefPattern(
                    id: UUID(),
                    title: "Belief in Transformation",
                    description: "'\(belief.text.prefix(30))' has shifted \(Int(delta)) points — a major evolution. What's driving the change?",
                    type: .evolution,
                    affectedBeliefIds: [belief.id],
                    icon: "arrow.up.right.circle",
                    color: "4CAF50"
                ))
            } else if delta < -25 {
                patterns.append(BeliefPattern(
                    id: UUID(),
                    title: "Belief Strengthening",
                    description: "'\(belief.text.prefix(30))' has gained \(Int(abs(delta))) points — becoming more entrenched. Is this warranted?",
                    type: .evolution,
                    affectedBeliefIds: [belief.id],
                    icon: "lock.fill",
                    color: "EF5350"
                ))
            }
        }

        return patterns
    }

    private func themeIcon(for name: String) -> String {
        switch name {
        case "Relationships": return "person.2"
        case "Self-Worth": return "heart"
        case "Control": return "gearshape"
        case "Future": return "clock"
        default: return "sparkles"
        }
    }

    private func themeColor(for name: String) -> String {
        switch name {
        case "Relationships": return "e879f9"
        case "Self-Worth": return "EF5350"
        case "Control": return "42A5F5"
        case "Future": return "FFCA28"
        default: return "B8B8B8"
        }
    }
}

// MARK: - Supporting Types

struct SocraticQuestion: Identifiable {
    let id: UUID
    let category: QuestionCategory
    let question: String
    let followUps: [String]

    enum QuestionCategory {
        case cognitiveDistortion(CognitiveDistortionType)
        case evidence
        case perspective
        case alternative
        case impact

        var icon: String {
            switch self {
            case .cognitiveDistortion: return "brain"
            case .evidence: return "doc.text.magnifyingglass"
            case .perspective: return "person.2"
            case .alternative: return "arrow.triangle.branch"
            case .impact: return "bolt"
            }
        }
    }
}

struct BeliefPattern: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: PatternCategory
    let affectedBeliefIds: [UUID]
    let icon: String
    let color: String

    enum PatternCategory {
        case theme
        case confidence
        case contradiction
        case evolution

        var colorSwiftUI: String { "" }
    }
}
