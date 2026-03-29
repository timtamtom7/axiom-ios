import Foundation
import SwiftUI

// MARK: - Community Circle Models

/// R12: Community Circle — shared belief groups and challenges
struct CommunityCircle: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var inviteCode: String
    var memberCount: Int
    var members: [CircleMember]
    var sharedChallenges: [SharedBeliefChallenge]
    var createdAt: Date
    var isJoined: Bool
    var circleColor: String
}

/// Member within a community circle
struct CircleMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var avatarInitials: String
    var beliefsShared: Int
    var challengesCompleted: Int
    var joinedAt: Date
}

/// Shared belief challenge within a circle
struct SharedBeliefChallenge: Identifiable, Codable, Equatable {
    let id: UUID
    var beliefText: String
    var authorId: UUID
    var authorName: String
    var evidenceCount: Int
    var supportLevel: SupportLevel
    var createdAt: Date
    var comments: [ChallengeComment]
    var isResolved: Bool

    enum SupportLevel: String, Codable {
        case strong = "strong"
        case moderate = "moderate"
        case weak = "weak"
        case undecided = "undecided"

        var color: Color {
            switch self {
            case .strong: return Theme.accentGreen
            case .moderate: return Theme.accentBlue
            case .weak: return Color.orange
            case .undecided: return Theme.textSecondary
            }
        }

        var label: String {
            switch self {
            case .strong: return "Strong"
            case .moderate: return "Moderate"
            case .weak: return "Weak"
            case .undecided: return "Undecided"
            }
        }
    }
}

/// Comment on a shared belief challenge
struct ChallengeComment: Identifiable, Codable, Equatable {
    let id: UUID
    var authorId: UUID
    var authorName: String
    var text: String
    var createdAt: Date
}

// MARK: - Community Circle Service

/// R12: Service for managing community circles and shared belief challenges
@MainActor
final class CommunityCircleService: ObservableObject {
    static let shared = CommunityCircleService()

    private let circlesKey = "community_circles"
    private let challengesKey = "community_challenges"

    @Published var circles: [CommunityCircle] = []
    @Published var joinedCircles: [CommunityCircle] = []

    private init() {
        loadCircles()
    }

    // MARK: - Circle Management

    /// Create a new community circle
    /// - Parameters:
    ///   - name: Name of the circle
    ///   - description: Description of the circle's purpose
    /// - Returns: The newly created community circle
    func createCircle(name: String, description: String) async throws -> CommunityCircle {
        let currentUser = CircleMember(
            id: UUID(),
            name: "You",
            avatarInitials: "Y",
            beliefsShared: 0,
            challengesCompleted: 0,
            joinedAt: Date()
        )

        let circle = CommunityCircle(
            id: UUID(),
            name: name,
            description: description,
            inviteCode: generateInviteCode(),
            memberCount: 1,
            members: [currentUser],
            sharedChallenges: [],
            createdAt: Date(),
            isJoined: true,
            circleColor: randomCircleColor()
        )

        circles.insert(circle, at: 0)
        updateJoinedCircles()
        saveCircles()
        return circle
    }

    /// Join an existing circle by invite code
    /// - Parameter code: The invite code for the circle
    /// - Returns: The joined community circle
    func joinCircle(code: String) async throws -> CommunityCircle {
        guard let index = circles.firstIndex(where: { $0.inviteCode == code }) else {
            throw CommunityCircleError.invalidInviteCode
        }

        let currentUser = CircleMember(
            id: UUID(),
            name: "You",
            avatarInitials: "Y",
            beliefsShared: 0,
            challengesCompleted: 0,
            joinedAt: Date()
        )

        circles[index].members.append(currentUser)
        circles[index].memberCount += 1
        circles[index].isJoined = true
        updateJoinedCircles()
        saveCircles()
        return circles[index]
    }

    /// Leave a circle
    func leaveCircle(_ circle: CommunityCircle) async throws {
        guard let index = circles.firstIndex(where: { $0.id == circle.id }) else {
            throw CommunityCircleError.circleNotFound
        }

        circles[index].members.removeAll { $0.name == "You" }
        circles[index].memberCount = max(0, circles[index].memberCount - 1)
        circles[index].isJoined = false
        updateJoinedCircles()
        saveCircles()
    }

    /// Get all circles
    func getCircles() -> [CommunityCircle] {
        return circles
    }

    /// Get only joined circles
    func getJoinedCircles() -> [CommunityCircle] {
        return circles.filter { $0.isJoined }
    }

    // MARK: - Challenge Management

    /// Add a shared belief challenge to a circle
    func addChallenge(to circleId: UUID, beliefText: String, supportLevel: SharedBeliefChallenge.SupportLevel) async throws {
        guard let index = circles.firstIndex(where: { $0.id == circleId }) else {
            throw CommunityCircleError.circleNotFound
        }

        let challenge = SharedBeliefChallenge(
            id: UUID(),
            beliefText: beliefText,
            authorId: UUID(),
            authorName: "You",
            evidenceCount: 0,
            supportLevel: supportLevel,
            createdAt: Date(),
            comments: [],
            isResolved: false
        )

        circles[index].sharedChallenges.insert(challenge, at: 0)

        // Update member stats
        if let memberIndex = circles[index].members.firstIndex(where: { $0.name == "You" }) {
            circles[index].members[memberIndex].beliefsShared += 1
        }

        updateJoinedCircles()
        saveCircles()
    }

    /// Add a comment to a challenge
    func addComment(to challengeId: UUID, in circleId: UUID, text: String) async throws {
        guard let circleIndex = circles.firstIndex(where: { $0.id == circleId }),
              let challengeIndex = circles[circleIndex].sharedChallenges.firstIndex(where: { $0.id == challengeId }) else {
            throw CommunityCircleError.challengeNotFound
        }

        let comment = ChallengeComment(
            id: UUID(),
            authorId: UUID(),
            authorName: "You",
            text: text,
            createdAt: Date()
        )

        circles[circleIndex].sharedChallenges[challengeIndex].comments.append(comment)
        updateJoinedCircles()
        saveCircles()
    }

    /// Resolve a challenge
    func resolveChallenge(_ challengeId: UUID, in circleId: UUID) async throws {
        guard let circleIndex = circles.firstIndex(where: { $0.id == circleId }),
              let challengeIndex = circles[circleIndex].sharedChallenges.firstIndex(where: { $0.id == challengeId }) else {
            throw CommunityCircleError.challengeNotFound
        }

        circles[circleIndex].sharedChallenges[challengeIndex].isResolved = true

        if let memberIndex = circles[circleIndex].members.firstIndex(where: { $0.name == "You" }) {
            circles[circleIndex].members[memberIndex].challengesCompleted += 1
        }

        updateJoinedCircles()
        saveCircles()
    }

    // MARK: - Persistence

    private func loadCircles() {
        guard let data = UserDefaults.standard.data(forKey: circlesKey),
              let decoded = try? JSONDecoder().decode([CommunityCircle].self, from: data) else {
            circles = Self.sampleCircles
            updateJoinedCircles()
            return
        }
        circles = decoded
        updateJoinedCircles()
    }

    private func saveCircles() {
        if let encoded = try? JSONEncoder().encode(circles) {
            UserDefaults.standard.set(encoded, forKey: circlesKey)
        }
    }

    private func updateJoinedCircles() {
        joinedCircles = circles.filter { $0.isJoined }
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func randomCircleColor() -> String {
        let colors = ["blue", "green", "purple", "orange", "pink", "teal"]
        return colors.randomElement()!
    }

    // MARK: - Sample Data

    private static let sampleCircles: [CommunityCircle] = [
        CommunityCircle(
            id: UUID(),
            name: "Daily Belief Check-in",
            description: "Share your daily belief updates and get feedback from fellow believers.",
            inviteCode: "DAILY01",
            memberCount: 24,
            members: [
                CircleMember(id: UUID(), name: "Alex", avatarInitials: "AL", beliefsShared: 12, challengesCompleted: 8, joinedAt: Date().addingTimeInterval(-86400 * 14)),
                CircleMember(id: UUID(), name: "Sam", avatarInitials: "SM", beliefsShared: 7, challengesCompleted: 5, joinedAt: Date().addingTimeInterval(-86400 * 7))
            ],
            sharedChallenges: [
                SharedBeliefChallenge(
                    id: UUID(),
                    beliefText: "Regular belief audits improve mental clarity over time.",
                    authorId: UUID(),
                    authorName: "Alex",
                    evidenceCount: 3,
                    supportLevel: .strong,
                    createdAt: Date().addingTimeInterval(-3600),
                    comments: [],
                    isResolved: false
                )
            ],
            createdAt: Date().addingTimeInterval(-86400 * 30),
            isJoined: false,
            circleColor: "blue"
        ),
        CommunityCircle(
            id: UUID(),
            name: "Evidence Collectors",
            description: "A group focused on gathering and sharing evidence for belief statements.",
            inviteCode: "EVDCE2",
            memberCount: 15,
            members: [
                CircleMember(id: UUID(), name: "Jordan", avatarInitials: "JD", beliefsShared: 20, challengesCompleted: 15, joinedAt: Date().addingTimeInterval(-86400 * 20))
            ],
            sharedChallenges: [
                SharedBeliefChallenge(
                    id: UUID(),
                    beliefText: "Cognitive behavioral techniques are more effective than medication for mild anxiety.",
                    authorId: UUID(),
                    authorName: "Jordan",
                    evidenceCount: 8,
                    supportLevel: .moderate,
                    createdAt: Date().addingTimeInterval(-7200),
                    comments: [],
                    isResolved: false
                )
            ],
            createdAt: Date().addingTimeInterval(-86400 * 45),
            isJoined: false,
            circleColor: "green"
        ),
        CommunityCircle(
            id: UUID(),
            name: "Critical Thinkers",
            description: "Challenge assumptions and explore beliefs from multiple perspectives.",
            inviteCode: "CRITIQ",
            memberCount: 42,
            members: [
                CircleMember(id: UUID(), name: "Riley", avatarInitials: "RL", beliefsShared: 35, challengesCompleted: 28, joinedAt: Date().addingTimeInterval(-86400 * 60))
            ],
            sharedChallenges: [],
            createdAt: Date().addingTimeInterval(-86400 * 90),
            isJoined: false,
            circleColor: "purple"
        )
    ]
}

// MARK: - Errors

enum CommunityCircleError: LocalizedError {
    case circleNotFound
    case challengeNotFound
    case invalidInviteCode
    case notAMember

    var errorDescription: String? {
        switch self {
        case .circleNotFound: return "Circle not found"
        case .challengeNotFound: return "Challenge not found"
        case .invalidInviteCode: return "Invalid invite code"
        case .notAMember: return "You are not a member of this circle"
        }
    }
}
