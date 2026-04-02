import Foundation

/// R11: Thought pattern detection and tracking across beliefs
final class PatternDetectionService: ObservableObject, @unchecked Sendable {
    static let shared = PatternDetectionService()

    private init() {}

    // MARK: - Pattern Analysis

    func analyzeAllPatterns(in beliefs: [Belief]) -> [DistortionPattern] {
        return []
    }

    // MARK: - Core Belief Detection

    /// Detect recurring themes and core beliefs across all beliefs
    func detectCoreBeliefs(from beliefs: [Belief]) -> [DetectedCoreBelief] {
        var coreThemes: [String: [Belief]] = [:]

        let themeKeywords: [String: [String]] = [
            "Not Good Enough": ["not good enough", "not enough", "not worthy", "inadequate", "not competent", "not smart enough"],
            "Unlovable": ["unlovable", "not loved", "not lovable", "not wanted", "abandoned", "alone"],
            "Must Be Perfect": ["perfect", "failure", "let them down", "mess up", "not enough", "must be perfect"],
            "Helplessness": ["can't", "unable", "hopeless", "powerless", "out of control", "stuck"],
            "Burden": ["burden", "weight", "drag them down", "inconvenience", "problem"],
        ]

        for belief in beliefs {
            let text = belief.text.lowercased()
            for (theme, keywords) in themeKeywords {
                if keywords.contains(where: { text.contains($0) }) {
                    coreThemes[theme, default: []].append(belief)
                }
            }
        }

        return coreThemes.compactMap { (theme, relatedBeliefs) in
            guard !relatedBeliefs.isEmpty else { return nil }
            return DetectedCoreBelief(
                theme: theme,
                relatedBeliefs: relatedBeliefs,
                frequency: relatedBeliefs.count,
                averageScore: relatedBeliefs.map(\.score).reduce(0, +) / Double(relatedBeliefs.count)
            )
        }.sorted { $0.frequency > $1.frequency }
    }

    // MARK: - Distortion Patterns

    /// Track which distortions appear most frequently and when
    func detectDistortionPatterns(from beliefs: [Belief]) -> [DistortionPattern] {
        let analysisService = AIBeliefService.shared
        var distortionTimeline: [CognitiveDistortion: [(Date, String)]] = [:]

        for belief in beliefs {
            let analysis = analysisService.analyzeBelief(belief)
            for distortion in analysis.distortions {
                distortionTimeline[distortion, default: []].append((belief.createdAt, belief.text))
            }
        }

        return distortionTimeline.compactMap { (distortion, entries) in
            guard !entries.isEmpty else { return nil }
            return DistortionPattern(
                distortion: distortion,
                occurrences: entries.count,
                recentExamples: entries.suffix(3).reversed().map { $0.1 },
                firstDetected: entries.map(\.0).min() ?? Date(),
                lastDetected: entries.map(\.0).max() ?? Date()
            )
        }.sorted { $0.occurrences > $1.occurrences }
    }

    // MARK: - Trigger Detection

    /// Link beliefs to emotional triggers based on evidence timing
    func detectTriggers(from beliefs: [Belief]) -> [BeliefTrigger] {
        var triggers: [BeliefTrigger] = []

        let calendar = Calendar.current
        let evidenceByWeekday = beliefs.flatMap { $0.evidenceItems }
            .reduce(into: [Int: Int]()) { acc, ev in
                let weekday = calendar.component(.weekday, from: ev.createdAt)
                acc[weekday, default: 0] += 1
            }

        if let peakDay = evidenceByWeekday.max(by: { $0.value < $1.value }) {
            let dayName = calendar.weekdaySymbols[peakDay.key - 1]
            triggers.append(BeliefTrigger(
                triggerType: .timeBased,
                description: "You tend to examine beliefs most on \(dayName)s",
                associatedBeliefs: beliefs.filter { belief in
                    belief.evidenceItems.contains { ev in
                        calendar.component(.weekday, from: ev.createdAt) == peakDay.key
                    }
                }
            ))
        }

        // Core beliefs tend to come up during stress
        let coreBeliefs = beliefs.filter(\.isCore)
        if !coreBeliefs.isEmpty {
            triggers.append(BeliefTrigger(
                triggerType: .stressRelated,
                description: "Your \(coreBeliefs.count) core belief(s) are most active when processing stress",
                associatedBeliefs: coreBeliefs
            ))
        }

        // Low-scoring beliefs often triggered by failure
        let lowScoringBeliefs = beliefs.filter { $0.score < 40 }
        if !lowScoringBeliefs.isEmpty {
            triggers.append(BeliefTrigger(
                triggerType: .failureRelated,
                description: "Challenged beliefs (score <40) are often triggered by perceived failures",
                associatedBeliefs: lowScoringBeliefs
            ))
        }

        return triggers
    }

    // MARK: - Cognitive Distortion Frequency

    /// Report distortion frequency over time
    func distortionFrequency(for beliefs: [Belief], inDays days: Int = 30) -> [(CognitiveDistortion, Int)] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentBeliefs = beliefs.filter { $0.createdAt >= cutoffDate }
        return AIBeliefService.shared.distortionSummary(for: recentBeliefs).map { ($0.0, $0.1) }
    }

    // MARK: - Pattern Narrative

    /// Generate a natural language summary of detected patterns
    func generatePatternNarrative(for beliefs: [Belief]) -> String {
        let coreBeliefs = detectCoreBeliefs(from: beliefs)
        let distortionPatterns = detectDistortionPatterns(from: beliefs)
        let triggers = detectTriggers(from: beliefs)

        var narrative: [String] = []

        if !coreBeliefs.isEmpty {
            let topCore = coreBeliefs.prefix(2)
            let themes = topCore.map { "'\($0.theme)'" }.joined(separator: " and ")
            narrative.append("Your core themes of \(themes) appear in \(topCore.map { "\($0.frequency) beliefs" }.joined(separator: " and ")).")
        }

        if let topDistortion = distortionPatterns.first {
            narrative.append("You tend toward \(topDistortion.distortion.rawValue.lowercased()) — seen in \(topDistortion.occurrences) belief(s).")
        }

        if let topTrigger = triggers.first {
            narrative.append(topTrigger.description)
        }

        if narrative.isEmpty {
            return "Keep adding beliefs and evidence to see patterns emerge."
        }

        return narrative.joined(separator: " ")
    }
}

// MARK: - Supporting Types

struct DetectedCoreBelief: Identifiable {
    let id = UUID()
    let theme: String
    let relatedBeliefs: [Belief]
    let frequency: Int
    let averageScore: Double
}

struct DistortionPattern: Identifiable {
    let id = UUID()
    let distortion: CognitiveDistortion
    let occurrences: Int
    let recentExamples: [String]
    let firstDetected: Date
    let lastDetected: Date

    var isActive: Bool {
        Calendar.current.isDateInToday(lastDetected) ||
        Calendar.current.isDateInYesterday(lastDetected)
    }
}

struct BeliefTrigger: Identifiable {
    let id = UUID()
    let triggerType: TriggerType
    let description: String
    let associatedBeliefs: [Belief]

    enum TriggerType {
        case timeBased
        case stressRelated
        case failureRelated
        case socialRelated

        var icon: String {
            switch self {
            case .timeBased:    return "clock"
            case .stressRelated: return "bolt.fill"
            case .failureRelated: return "xmark.circle"
            case .socialRelated:  return "person.2"
            }
        }
    }
}
