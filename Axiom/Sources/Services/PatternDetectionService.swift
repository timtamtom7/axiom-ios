import Foundation

@MainActor
final class PatternDetectionService {
    static let shared = PatternDetectionService()

    private init() {}

    // MARK: - Time Patterns

    func detectTimePatterns(in beliefs: [Belief]) -> [Pattern] {
        var patterns: [Pattern] = []

        let allEvidence = beliefs.flatMap { $0.evidenceItems }
        let calendar = Calendar.current

        var weekdayCounts: [Int: Int] = [:]
        var hourCounts: [Int: Int] = [:]

        for evidence in allEvidence {
            let weekday = calendar.component(.weekday, from: evidence.createdAt)
            let hour = calendar.component(.hour, from: evidence.createdAt)
            weekdayCounts[weekday, default: 0] += 1
            hourCounts[hour, default: 0] += 1
        }

        if let mostActiveWeekday = weekdayCounts.max(by: { $0.value < $1.value }) {
            let dayName = calendar.weekdaySymbols[mostActiveWeekday.key - 1]
            patterns.append(Pattern(
                title: "Most Active Day",
                description: "You tend to work on beliefs most on \(dayName)s",
                type: .time
            ))
        }

        let morningCount = hourCounts.filter { $0.key >= 5 && $0.key < 12 }.values.reduce(0, +)
        let afternoonCount = hourCounts.filter { $0.key >= 12 && $0.key < 17 }.values.reduce(0, +)
        let eveningCount = hourCounts.filter { $0.key >= 17 && $0.key < 22 }.values.reduce(0, +)
        let nightCount = hourCounts.filter { $0.key >= 22 || $0.key < 5 }.values.reduce(0, +)

        let maxTimeSlot = [("Morning", morningCount), ("Afternoon", afternoonCount), ("Evening", eveningCount), ("Night", nightCount)]
            .max(by: { $0.1 < $1.1 })

        if let slot = maxTimeSlot, slot.1 > 0 {
            patterns.append(Pattern(
                title: "Peak Working Time",
                description: "You typically work on beliefs in the \(slot.0.lowercased())",
                type: .time
            ))
        }

        let weekdayEvidence = weekdayCounts.filter { $0.key >= 2 && $0.key <= 6 }.values.reduce(0, +)
        let weekendEvidence = weekdayCounts.filter { $0.key == 1 || $0.key == 7 }.values.reduce(0, +)

        if weekdayEvidence > 0 || weekendEvidence > 0 {
            let preferred = weekdayEvidence > weekendEvidence ? "weekdays" : "weekends"
            patterns.append(Pattern(
                title: "Day Preference",
                description: "You prefer working on beliefs on \(preferred)",
                type: .time
            ))
        }

        return patterns
    }

    // MARK: - Score Patterns

    func detectScorePatterns(in beliefs: [Belief]) -> [Pattern] {
        var patterns: [Pattern] = []

        let lowCount = beliefs.filter { $0.scoreCategory == .low }.count
        let medCount = beliefs.filter { $0.scoreCategory == .medium }.count
        let highCount = beliefs.filter { $0.scoreCategory == .high }.count

        if beliefs.count > 0 {
            let lowPct = Double(lowCount) / Double(beliefs.count) * 100
            let highPct = Double(highCount) / Double(beliefs.count) * 100

            if lowPct > 50 {
                patterns.append(Pattern(
                    title: "Challenged Beliefs",
                    description: "Over half your beliefs lean toward low evidence scores — you're actively questioning assumptions",
                    type: .score
                ))
            } else if highPct > 50 {
                patterns.append(Pattern(
                    title: "Strong Beliefs",
                    description: "Most of your beliefs have strong supporting evidence",
                    type: .score
                ))
            } else {
                patterns.append(Pattern(
                    title: "Mixed Evidence",
                    description: "Your beliefs show a balanced mix of evidence — keep exploring both sides",
                    type: .score
                ))
            }
        }

        let challengedBeliefs = beliefs.sorted { $0.score < $1.score }.prefix(3)
        if !challengedBeliefs.isEmpty {
            let names = challengedBeliefs.map { $0.text.prefix(30) }.joined(separator: ", ")
            patterns.append(Pattern(
                title: "Most Challenged",
                description: "These beliefs have the lowest evidence scores: \(names)...",
                type: .score
            ))
        }

        if !beliefs.isEmpty {
            let avgScore = beliefs.map(\.score).reduce(0, +) / Double(beliefs.count)
            let scoreLevel = avgScore >= 70 ? "strong" : avgScore >= 40 ? "moderate" : "developing"
            patterns.append(Pattern(
                title: "Overall Evidence Strength",
                description: "Your belief portfolio has a \(scoreLevel) average evidence score of \(Int(avgScore))%",
                type: .score
            ))
        }

        let beliefsWithHistory = beliefs.filter { $0.scoreHistory.count >= 2 }
        if !beliefsWithHistory.isEmpty {
            let avgVolatility = beliefsWithHistory.map { belief -> Double in
                let scores = belief.scoreHistory.map(\.score)
                let maxDelta = (scores.max() ?? 0) - (scores.min() ?? 0)
                return maxDelta
            }.reduce(0, +) / Double(beliefsWithHistory.count)

            if avgVolatility > 20 {
                patterns.append(Pattern(
                    title: "High Belief Volatility",
                    description: "Your beliefs tend to shift significantly as you add new evidence (avg shift: \(Int(avgVolatility))%)",
                    type: .score
                ))
            } else if avgVolatility < 5 {
                patterns.append(Pattern(
                    title: "Stable Beliefs",
                    description: "Your beliefs remain relatively stable as you gather evidence",
                    type: .score
                ))
            }
        }

        return patterns
    }

    // MARK: - Evidence Patterns

    func detectEvidencePatterns(in beliefs: [Belief]) -> [Pattern] {
        var patterns: [Pattern] = []

        let totalSupporting = beliefs.map(\.supportingCount).reduce(0, +)
        let totalContradicting = beliefs.map(\.contradictingCount).reduce(0, +)

        guard totalSupporting + totalContradicting > 0 else {
            patterns.append(Pattern(
                title: "Getting Started",
                description: "Add evidence to your beliefs to see patterns emerge",
                type: .evidence
            ))
            return patterns
        }

        let ratio = Double(totalSupporting) / Double(totalSupporting + totalContradicting) * 100

        if ratio > 70 {
            patterns.append(Pattern(
                title: "Confirmation Bias Watch",
                description: "71%+ of your evidence supports existing beliefs. Consider seeking contradicting evidence for balance.",
                type: .evidence
            ))
        } else if ratio < 30 {
            patterns.append(Pattern(
                title: "Active Skeptic",
                description: "Most of your evidence contradicts your beliefs — you're rigorously testing your assumptions",
                type: .evidence
            ))
        } else {
            patterns.append(Pattern(
                title: "Balanced Investigation",
                description: "You maintain a healthy balance of supporting and contradicting evidence",
                type: .evidence
            ))
        }

        if !beliefs.isEmpty {
            let avgEvidence = Double(beliefs.map(\.evidenceItems.count).reduce(0, +)) / Double(beliefs.count)
            if avgEvidence < 2 {
                patterns.append(Pattern(
                    title: "Early Stage",
                    description: "Most beliefs have limited evidence (avg: \(String(format: "%.1f", avgEvidence))). Consider adding more perspectives.",
                    type: .evidence
                ))
            } else if avgEvidence >= 5 {
                patterns.append(Pattern(
                    title: "Well-Documented Beliefs",
                    description: "Your beliefs are thoroughly researched with an average of \(String(format: "%.1f", avgEvidence)) evidence items each",
                    type: .evidence
                ))
            }
        }

        let contestedBeliefs = beliefs
            .filter { $0.supportingCount > 0 && $0.contradictingCount > 0 }
            .sorted { ($0.supportingCount + $0.contradictingCount) > ($1.supportingCount + $1.contradictingCount) }
            .prefix(3)

        if !contestedBeliefs.isEmpty {
            let names = contestedBeliefs.map { $0.text.prefix(25) }.joined(separator: ", ")
            patterns.append(Pattern(
                title: "Most Contested",
                description: "These beliefs have the most back-and-forth evidence: \(names)...",
                type: .evidence
            ))
        }

        return patterns
    }

    // MARK: - Behavioral Patterns

    func detectBehavioralPatterns(in beliefs: [Belief]) -> [Pattern] {
        var patterns: [Pattern] = []

        let coreCount = beliefs.filter(\.isCore).count
        if beliefs.count > 0 {
            let coreRatio = Double(coreCount) / Double(beliefs.count) * 100
            if coreRatio > 30 {
                patterns.append(Pattern(
                    title: "Foundation Builder",
                    description: "You focus heavily on core beliefs (>\(Int(coreRatio))% are marked core)",
                    type: .behavioral
                ))
            }
        }

        let calendar = Calendar.current
        let recentBeliefs = beliefs.filter {
            calendar.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 0 < 30
        }
        let olderBeliefs = beliefs.filter {
            calendar.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 0 >= 90
        }

        if !recentBeliefs.isEmpty && !olderBeliefs.isEmpty {
            patterns.append(Pattern(
                title: "Continuous Learner",
                description: "You've added \(recentBeliefs.count) new belief(s) in the last 30 days while maintaining \(olderBeliefs.count) long-term belief(s)",
                type: .behavioral
            ))
        }

        let archivedCount = DatabaseService.shared.archivedBeliefs.count
        if archivedCount > 0 {
            patterns.append(Pattern(
                title: "Regular Reviewer",
                description: "You've archived \(archivedCount) belief(s) — you're actively curating your belief portfolio",
                type: .behavioral
            ))
        }

        return patterns
    }

    // MARK: - All Patterns

    func analyzeAllPatterns(in beliefs: [Belief]) -> [Pattern] {
        var allPatterns: [Pattern] = []
        allPatterns.append(contentsOf: detectTimePatterns(in: beliefs))
        allPatterns.append(contentsOf: detectScorePatterns(in: beliefs))
        allPatterns.append(contentsOf: detectEvidencePatterns(in: beliefs))
        allPatterns.append(contentsOf: detectBehavioralPatterns(in: beliefs))
        return allPatterns
    }
}

// MARK: - Supporting Types

extension PatternDetectionService {
    struct Pattern: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let type: PatternType
    }

    enum PatternType {
        case time
        case score
        case evidence
        case behavioral

        var icon: String {
            switch self {
            case .time: return "clock"
            case .score: return "chart.bar"
            case .evidence: return "doc.text"
            case .behavioral: return "person.pattern"
            }
        }

        var color: String {
            switch self {
            case .time: return "42A5F5"
            case .score: return "FFCA28"
            case .evidence: return "4CAF50"
            case .behavioral: return "e879f9"
            }
        }
    }
}
