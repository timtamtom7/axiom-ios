import Foundation

/// R22: Social belief challenges and debate competitions
final class SocialChallengeService: @unchecked Sendable {
    static let shared = SocialChallengeService()

    private let baseURL = "https://axiom.app/challenge"
    private var activeChallenges: [Challenge] = []
    private var leaderboardEntries: [LeaderboardEntry] = []

    private init() {
        loadFromStorage()
    }

    // MARK: - Challenge Management

    /// Challenge a friend to a belief debate
    /// - Parameters:
    ///   - beliefId: The UUID of the belief to debate
    ///   - friendEmail: Email of the friend to challenge
    /// - Returns: The created challenge
    func createChallenge(beliefId: UUID, friendEmail: String) async throws -> Challenge {
        // Look up the belief text from storage
        let beliefText = try await fetchBeliefText(beliefId: beliefId)
        let currentUserName = try await fetchCurrentUserName()

        let challenge = Challenge(
            id: UUID(),
            beliefText: beliefText,
            challengerName: currentUserName,
            responderName: nil,
            status: .pending,
            beliefId: beliefId,
            createdAt: Date()
        )

        // Generate challenge link
        let challengeLink = "\(baseURL)/\(challenge.id.uuidString)"

        // Send invite via email (stub)
        try await sendChallengeEmail(to: friendEmail, challengeLink: challengeLink, beliefText: beliefText)

        // Persist locally
        activeChallenges.append(challenge)
        saveToStorage()

        return challenge
    }

    /// Accept or decline a challenge
    func respondToChallenge(challengeId: UUID, response: ChallengeResponse) async throws {
        guard let index = activeChallenges.firstIndex(where: { $0.id == challengeId }) else {
            throw ChallengeError.challengeNotFound
        }

        switch response {
        case .accept:
            activeChallenges[index].responderName = try await fetchCurrentUserName()
            activeChallenges[index].status = .accepted
        case .decline:
            activeChallenges[index].status = .declined
        }

        saveToStorage()
    }

    /// Submit the result of a completed debate
    func submitDebateResult(challengeId: UUID, debate: DebateResult) async throws {
        guard let index = activeChallenges.firstIndex(where: { $0.id == challengeId }) else {
            throw ChallengeError.challengeNotFound
        }

        activeChallenges[index].status = .completed

        // Update leaderboard with debate result
        if let winner = debate.winner {
            try await updateLeaderboard(
                winnerName: winner,
                points: 3,
                beliefsResolved: 1
            )

            // Award fewer points to loser
            let loser = winner == activeChallenges[index].challengerName
                ? activeChallenges[index].responderName
                : activeChallenges[index].challengerName
            if let loserName = loser {
                try await updateLeaderboard(
                    winnerName: loserName,
                    points: 1,
                    beliefsResolved: 0
                )
            }
        }

        saveToStorage()
    }

    // MARK: - Leaderboard

    /// Fetch the current leaderboard
    func fetchLeaderboard() async throws -> [LeaderboardEntry] {
        return leaderboardEntries.sorted { $0.score > $1.score }
    }

    /// Get a user's current rank
    func fetchUserRank(userId: UUID) async throws -> Int? {
        guard let entry = leaderboardEntries.first(where: { $0.id == userId }) else {
            return nil
        }
        let sorted = leaderboardEntries.sorted { $0.score > $1.score }
        return sorted.firstIndex(where: { $0.id == userId }).map { $0 + 1 }
    }

    // MARK: - Private Helpers

    private func fetchBeliefText(beliefId: UUID) async throws -> String {
        // In production, fetch from DatabaseService
        return "Belief text for \(beliefId)"
    }

    private func fetchCurrentUserName() async throws -> String {
        return "CurrentUser"
    }

    private func sendChallengeEmail(to email: String, challengeLink: String, beliefText: String) async throws {
        // Stub: In production, use a real email service
        print("Sending challenge email to \(email): \(challengeLink) for belief: \(beliefText)")
    }

    private func updateLeaderboard(winnerName: String, points: Int, beliefsResolved: Int) async throws {
        if let index = leaderboardEntries.firstIndex(where: { $0.name == winnerName }) {
            leaderboardEntries[index].score += points
            leaderboardEntries[index].beliefsResolved += beliefsResolved
        } else {
            let newEntry = LeaderboardEntry(
                id: UUID(),
                name: winnerName,
                score: points,
                beliefsResolved: beliefsResolved
            )
            leaderboardEntries.append(newEntry)
        }
    }

    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(activeChallenges) {
            UserDefaults.standard.set(encoded, forKey: "axiom_challenges")
        }
        if let encoded = try? JSONEncoder().encode(leaderboardEntries) {
            UserDefaults.standard.set(encoded, forKey: "axiom_leaderboard")
        }
    }

    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "axiom_challenges"),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: data) {
            activeChallenges = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "axiom_leaderboard"),
           let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            leaderboardEntries = decoded
        }
    }
}

// MARK: - Models

extension SocialChallengeService {
    struct Challenge: Identifiable, Codable {
        let id: UUID
        let beliefText: String
        let challengerName: String
        var responderName: String?
        var status: Status
        let beliefId: UUID
        let createdAt: Date

        enum Status: String, Codable {
            case pending
            case accepted
            case declined
            case completed
        }
    }

    enum ChallengeResponse {
        case accept
        case decline
    }

    struct DebateResult: Codable {
        let challengerScore: Int
        let responderScore: Int
        let winner: String?
        let evidenceUsed: [String]
    }

    struct LeaderboardEntry: Identifiable, Codable {
        let id: UUID
        var name: String
        var score: Int
        var beliefsResolved: Int
    }
}

// MARK: - Errors

extension SocialChallengeService {
    enum ChallengeError: LocalizedError {
        case challengeNotFound
        case notAuthorized
        case debateNotComplete

        var errorDescription: String? {
            switch self {
            case .challengeNotFound: return "Challenge not found"
            case .notAuthorized: return "Not authorized to perform this action"
            case .debateNotComplete: return "Debate has not been completed yet"
            }
        }
    }
}
