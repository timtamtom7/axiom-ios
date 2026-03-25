import Foundation
import AppIntents

@MainActor
final class AIStressTestService: ObservableObject {
    @Published var challenges: [StressChallenge] = []
    @Published var isLoading = false

    struct StressChallenge: Identifiable {
        let id = UUID()
        let question: String
        var userResponse: String = ""
    }

    // MARK: - Static Challenge Bank (Fallback)
    private let staticChallenges: [String] = [
        "What specific evidence supports this belief? Be precise — not feelings, but concrete events.",
        "Is this belief a conclusion or a interpretation? What other interpretations are possible?",
        "Has this belief ever been tested? What happened when you acted against it?",
        "Who taught you this belief? Did they have your best interests in mind?",
        "What would the opposite belief look like in practice? Have you experienced it?",
        "Are you confusing a behavior with an identity? Can you change the behavior without changing who you are?",
        "What would you tell a close friend if they held this belief about themselves?",
        "Is this belief helping you or protecting you from something?",
        "What evidence have you ignored or dismissed that contradicts this belief?",
        "How does this belief serve you — even if it's painful?"
    ]

    func generateChallenges(for belief: Belief) async {
        await MainActor.run {
            self.isLoading = true
            self.challenges = []
        }

        // Attempt to use Apple Intelligence via App Intents
        // Fallback to curated challenge bank
        let selectedChallenges = selectChallenges(for: belief)

        await MainActor.run {
            self.challenges = selectedChallenges
            self.isLoading = false
        }
    }

    private func selectChallenges(for belief: Belief) -> [StressChallenge] {
        // Shuffle and pick 5 unique challenges
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

    func getAnalysis(for belief: Belief) async -> String {
        // Placeholder for AI analysis — in production would call Apple Intelligence
        let supporting = belief.evidenceItems.filter { $0.type == .support }
        let contradicting = belief.evidenceItems.filter { $0.type == .contradict }

        var analysis = "## Belief Analysis\n\n"
        analysis += "**Belief:** \(belief.text)\n\n"
        analysis += "**Evidence For:** \(supporting.count) items\n"
        for item in supporting {
            analysis += "- \(item.text)\n"
        }
        analysis += "\n**Evidence Against:** \(contradicting.count) items\n"
        for item in contradicting {
            analysis += "- \(item.text)\n"
        }
        analysis += "\n**Score:** \(Int(belief.score))/100\n\n"

        if contradicting.count > supporting.count {
            analysis += "The weight of evidence leans toward questioning this belief."
        } else if supporting.count > contradicting.count {
            analysis += "The evidence currently supports maintaining this belief — but stress-test it further."
        } else {
            analysis += "Evidence is balanced. Consider this belief a working hypothesis."
        }

        return analysis
    }
}
