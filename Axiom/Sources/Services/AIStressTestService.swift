import Foundation

@MainActor
final class AIStressTestService: ObservableObject {
    @Published var challenges: [StressChallenge] = []
    @Published var conversationMessages: [ConversationMessage] = []
    @Published var isLoading = false
    @Published var isInDeepDive = false

    struct StressChallenge: Identifiable {
        let id = UUID()
        let question: String
        var userResponse: String = ""
    }

    struct ConversationMessage: Identifiable {
        let id = UUID()
        let role: MessageRole
        let text: String
        let timestamp: Date

        enum MessageRole {
            case user
            case ai
        }
    }

    // MARK: - Static Challenge Bank (Fallback)
    private let staticChallenges: [String] = [
        "What specific evidence supports this belief? Be precise — not feelings, but concrete events.",
        "Is this belief a conclusion or an interpretation? What other interpretations are possible?",
        "Has this belief ever been tested? What happened when you acted against it?",
        "Who taught you this belief? Did they have your best interests in mind?",
        "What would the opposite belief look like in practice? Have you experienced it?",
        "Are you confusing a behavior with an identity? Can you change the behavior without changing who you are?",
        "What would you tell a close friend if they held this belief about themselves?",
        "Is this belief helping you or protecting you from something?",
        "What evidence have you ignored or dismissed that contradicts this belief?",
        "How does this belief serve you — even if it's painful?"
    ]

    private let openingQuestions: [String] = [
        "What first comes to mind when you think about this belief?",
        "When did you first notice this belief taking hold?",
        "What's the strongest piece of evidence you have for this belief?",
        "Who in your life would agree with this belief? Who would dispute it?"
    ]

    private let opposingViewpoints: [String] = [
        "Have you considered that this belief might be a generalization that doesn't hold in all cases?",
        "What would a therapist say about the origin of this belief?",
        "Is it possible this belief developed as a coping mechanism that was adaptive in the past but isn't serving you now?",
        "What would someone who loves you unconditionally say about this belief?"
    ]

    func generateChallenges(for belief: Belief) async {
        await MainActor.run {
            self.isLoading = true
            self.challenges = []
        }

        let selectedChallenges = selectChallenges(for: belief)

        await MainActor.run {
            self.challenges = selectedChallenges
            self.isLoading = false
        }
    }

    private func selectChallenges(for belief: Belief) -> [StressChallenge] {
        let shuffled = staticChallenges.shuffled()
        return Array(shuffled.prefix(5)).map { question in
            StressChallenge(question: question)
        }
    }

    func submitResponse(to challengeId: UUID, response: String) {
        if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
            challenges[index].userResponse = response
        }
    }

    // MARK: - AI Deep Dive Conversation

    func startDeepDive(for belief: Belief) {
        conversationMessages = []
        isInDeepDive = true
        let opening = openingQuestions.randomElement() ?? openingQuestions[0]
        addAIMessage("Let's explore this belief together. \(opening)")
    }

    func sendUserMessage(_ text: String, belief: Belief) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        addUserMessage(text)
        generateAIResponse(to: text, belief: belief)
    }

    private func addUserMessage(_ text: String) {
        conversationMessages.append(ConversationMessage(
            role: .user,
            text: text,
            timestamp: Date()
        ))
    }

    private func addAIMessage(_ text: String) {
        conversationMessages.append(ConversationMessage(
            role: .ai,
            text: text,
            timestamp: Date()
        ))
    }

    private func generateAIResponse(to userText: String, belief: Belief) {
        isLoading = true

        // Simulate AI response based on keywords and context
        let lowerText = userText.lowercased()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            var response: String

            if lowerText.contains("why") || lowerText.contains("how") {
                response = self.generateSocraticResponse(to: userText, belief: belief)
            } else if lowerText.contains("common") || lowerText.contains("everyone") {
                response = "This belief is more common than you might think. Many people hold similar beliefs as a result of early life experiences. The question is whether it's serving you now."
            } else if lowerText.contains("evidence") || lowerText.contains("prove") {
                response = "Let's examine that evidence critically. Can you point to a specific, verifiable event — not a feeling or interpretation? How certain are you that this evidence is accurate and complete?"
            } else if lowerText.contains("change") || lowerText.contains("different") {
                response = "Interesting thought. If this belief were different, how would your daily life change? What would you do differently? Sometimes exploring the alternative reveals how conditional our beliefs really are."
            } else if self.conversationMessages.count > 4 && Bool.random() {
                // After a few exchanges, occasionally suggest opposing viewpoint
                response = self.opposingViewpoints.randomElement() ?? "Keep questioning. What you're doing here is the hardest kind of work — examining the foundations of how you see yourself."
            } else {
                let genericResponses = [
                    "That's worth sitting with. What emotion comes up when you examine this belief closely?",
                    "Thank you for being honest with yourself. Is this belief something you chose, or something you inherited?",
                    "I appreciate your willingness to examine this. What would a younger version of you think if they heard you say this now?",
                    "Let me ask you this: if you dropped this belief entirely, what's the worst that could happen? What's the best?",
                    "There's no right answer here — just honest examination. What does your gut tell you when you really scrutinize this?"
                ]
                response = genericResponses.randomElement() ?? "Keep going. This kind of reflection is how beliefs loosen their grip."
            }

            self.addAIMessage(response)
            self.isLoading = false
        }
    }

    private func generateSocraticResponse(to question: String, belief: Belief) -> String {
        // Socratic questioning style
        let socratic = [
            "That's a thoughtful question. Before I answer, what do you think the answer might be?",
            "Interesting that you ask. Most people don't question the questioner. What specifically prompted this?",
            "I can share perspectives, but I'd rather you discover the answer. What have your own observations told you?",
            "Rather than me telling you, let's examine it together. What would changing your answer mean for this belief?",
            "Good question. Sometimes the questions we ask reveal more than the answers we find. What do you think is underneath this question?"
        ]
        return socratic.randomElement() ?? "Keep asking questions. The answers are within you."
    }

    func endDeepDive() {
        isInDeepDive = false
    }

    // MARK: - Analysis

    func getAnalysis(for belief: Belief) async throws -> String {
        let supporting = belief.evidenceItems.filter { $0.type == .support }
        let contradicting = belief.evidenceItems.filter { $0.type == .contradict }
        let coreLabel = belief.isCore ? "Core" : "Surface"
        let connections = DatabaseService.shared.connectionsFor(beliefId: belief.id)

        var analysis = "## Belief Analysis\n\n"
        analysis += "**Belief:** \(belief.text)\n"
        analysis += "**Classification:** \(coreLabel) belief\n"
        if let root = belief.rootCause {
            analysis += "**Origin:** \(root)\n"
        }
        analysis += "\n**Evidence For:** \(supporting.count) items\n"
        for item in supporting.prefix(5) {
            analysis += "- [\(item.confidenceLabel)] \(item.text)\n"
        }
        analysis += "\n**Evidence Against:** \(contradicting.count) items\n"
        for item in contradicting.prefix(5) {
            analysis += "- [\(item.confidenceLabel)] \(item.text)\n"
        }
        analysis += "\n**Connections:** \(connections.count) linked beliefs\n"
        analysis += "\n**Score:** \(Int(belief.score))/100\n\n"

        if contradicting.count > supporting.count {
            analysis += "The weight of evidence leans toward questioning this belief."
        } else if supporting.count > contradicting.count {
            analysis += "The evidence currently supports maintaining this belief — but stress-test it further."
        } else {
            analysis += "Evidence is balanced. Consider this belief a working hypothesis."
        }

        if belief.isCore {
            analysis += "\n\nThis is marked as a **core belief**. Core beliefs are foundational and often stem from early life experiences. They can be changed, but it requires sustained effort and new evidence over time."
        }

        return analysis
    }

    // MARK: - AI Suggestions

    func suggestOpposingViewpoint(for belief: Belief) async throws -> String {
        let viewpoints = [
            "What if the opposite belief served you better? Consider: '\(oppositeOf(belief.text))'",
            "Cognitive reframing: Instead of '\(belief.text)', what about '\(reframe(belief.text))'?",
            "Common cognitive distortion detected: overgeneralization. Ask yourself — is this true ALL the time, for EVERYONE, in EVERY situation?",
            "Evidence-based challenge: What would need to be true for '\(belief.text)' to be FALSE?",
            "Compassion-focused perspective: If a child held this belief about themselves, what would you say to them?"
        ]
        return viewpoints.randomElement() ?? "Keep examining this belief from different angles."
    }

    private func oppositeOf(_ text: String) -> String {
        if text.lowercased().contains("not ") || text.lowercased().contains("can't ") || text.lowercased().contains("don't ") {
            return text.replacingOccurrences(of: "not ", with: "").replacingOccurrences(of: "can't ", with: "can ").replacingOccurrences(of: "don't ", with: "do ")
        }
        return "Not " + text
    }

    private func reframe(_ text: String) -> String {
        text.replacingOccurrences(of: "I am ", with: "I am learning to be ").replacingOccurrences(of: "I ", with: "I sometimes ")
    }
}
