import Foundation
import SwiftUI

/// R16: AI Belief Agent - proactive belief work
/// - Daily prompts
/// - Evidence gathering
/// - Cognitive restructuring coaching
@MainActor
final class AIBeliefAgentService: ObservableObject {
    static let shared = AIBeliefAgentService()

    @Published var isActive: Bool = false
    @Published var dailyPrompt: AgentPrompt?
    @Published var coachingTips: [CoachingTip] = []
    @Published var lastSuggestion: EvidenceSuggestion?

    struct AgentPrompt: Codable, Identifiable {
        let id: UUID
        let title: String
        let description: String
        let targetBeliefId: UUID?
        let suggestedAction: String
        let priority: Priority
        let createdAt: Date

        enum Priority: String, Codable {
            case low, medium, high
        }
    }

    struct CoachingTip: Codable, Identifiable {
        let id: UUID
        let category: CoachingCategory
        let title: String
        let content: String
        let technique: String

        enum CoachingCategory: String, Codable {
            case cognitiveRestructuring = "Cognitive Restructuring"
            case evidenceGathering = "Evidence Gathering"
            case behavioralActivation = "Behavioral Activation"
            case mindfulness = "Mindfulness"
            case socraticQuestioning = "Socratic Questioning"
        }
    }

    struct EvidenceSuggestion: Codable, Identifiable {
        let id: UUID
        let beliefId: UUID
        let suggestion: String
        let type: EvidenceType
        let question: String

        enum EvidenceType: String, Codable {
            case supporting, opposing, neutral
        }
    }

    init() {
        loadAgentState()
    }

    private func loadAgentState() {
        isActive = UserDefaults.standard.bool(forKey: "ai_agent_active")
    }

    func activateAgent() {
        isActive = true
        UserDefaults.standard.set(true, forKey: "ai_agent_active")
        generateDailyPrompt()
        generateCoachingTips()
    }

    func deactivateAgent() {
        isActive = false
        UserDefaults.standard.set(false, forKey: "ai_agent_active")
    }

    /// R16: Generate daily prompt for proactive belief work
    func generateDailyPrompt() {
        let beliefs = DatabaseService.shared.allBeliefs

        guard let targetBelief = beliefs.min(by: { $0.score < $1.score }) else {
            dailyPrompt = nil
            return
        }

        let needsEvidence = targetBelief.evidenceItems.filter { $0.type == .support }.count < 2
        let needsReevaluation = targetBelief.score < 50

        if needsEvidence {
            dailyPrompt = AgentPrompt(
                id: UUID(),
                title: "Add Evidence",
                description: "Your belief '\(targetBelief.text)' could use more evidence. Challenge yourself to find 2 new pieces of evidence.",
                targetBeliefId: targetBelief.id,
                suggestedAction: "Add evidence for or against this belief",
                priority: .high,
                createdAt: Date()
            )
        } else if needsReevaluation {
            dailyPrompt = AgentPrompt(
                id: UUID(),
                title: "Re-evaluate Belief",
                description: "It's been a while since you re-evaluated '\(targetBelief.text)'. Has your perspective changed?",
                targetBeliefId: targetBelief.id,
                suggestedAction: "Update your evidence and score",
                priority: .medium,
                createdAt: Date()
            )
        } else {
            dailyPrompt = AgentPrompt(
                id: UUID(),
                title: "Connect Beliefs",
                description: "Explore how '\(targetBelief.text)' relates to your other beliefs.",
                targetBeliefId: targetBelief.id,
                suggestedAction: "View belief connections",
                priority: .low,
                createdAt: Date()
            )
        }
    }

    /// R16: Generate cognitive restructuring coaching tips
    func generateCoachingTips() {
        coachingTips = [
            CoachingTip(
                id: UUID(),
                category: .cognitiveRestructuring,
                title: "Thought Challenge",
                content: "When you notice a distressing thought, ask: What evidence supports this? What evidence contradicts it?",
                technique: "Three-Column Technique"
            ),
            CoachingTip(
                id: UUID(),
                category: .socraticQuestioning,
                title: "Socratic Questions",
                content: "What makes me believe this is true? What would I tell a friend in this situation?",
                technique: "Socratic Method"
            ),
            CoachingTip(
                id: UUID(),
                category: .evidenceGathering,
                title: "Balanced Evidence",
                content: "Gather at least 3 pieces of evidence for AND against any belief before forming a conclusion.",
                technique: "Pros/Cons Analysis"
            ),
            CoachingTip(
                id: UUID(),
                category: .behavioralActivation,
                title: "Action Challenge",
                content: "Identify one small action that contradicts your negative belief. Take that action today.",
                technique: "Behavioral Experiments"
            )
        ]
    }

    /// R16: Generate evidence suggestions for a belief
    func suggestEvidence(for beliefId: UUID) {
        guard let belief = DatabaseService.shared.allBeliefs.first(where: { $0.id == beliefId }) else {
            lastSuggestion = nil
            return
        }

        let opposingQuestions = [
            "What evidence suggests this might not be entirely true?",
            "Has there been a time when this belief was less true?",
            "What would someone who cares about you say about this?",
            "Are you confusing a feeling with a fact?",
            "What's the worst that could happen, and how would you cope?"
        ]

        lastSuggestion = EvidenceSuggestion(
            id: UUID(),
            beliefId: beliefId,
            suggestion: "Consider gathering evidence from multiple perspectives",
            type: .opposing,
            question: opposingQuestions.randomElement() ?? opposingQuestions[0]
        )
    }
}
