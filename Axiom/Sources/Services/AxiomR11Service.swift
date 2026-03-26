import Foundation

// R11: Community Debates, Evidence Library for Axiom
@MainActor
final class AxiomR11Service: ObservableObject {
    static let shared = AxiomR11Service()

    @Published var debates: [Debate] = []
    @Published var evidenceLibrary: [Evidence] = []

    private init() {}

    // MARK: - Community Debates

    struct Debate: Identifiable {
        let id: UUID
        let beliefId: UUID
        let title: String
        let arguments: [Argument]
        var upvotes: Int
        var downvotes: Int
    }

    struct Argument: Identifiable {
        let id: UUID
        let authorId: UUID
        let content: String
        var upvotes: Int
        var downvotes: Int
        let timestamp: Date
        let type: ArgumentType

        enum ArgumentType {
            case claim
            case evidence
            case counter
            case response
        }
    }

    func createDebate(beliefId: UUID, title: String) -> Debate {
        let debate = Debate(id: UUID(), beliefId: beliefId, title: title, arguments: [], upvotes: 0, downvotes: 0)
        debates.append(debate)
        return debate
    }

    func submitArgument(to debateId: UUID, content: String, type: Argument.ArgumentType) {
        guard let index = debates.firstIndex(where: { $0.id == debateId }) else { return }

        let argument = Argument(
            id: UUID(),
            authorId: UUID(),
            content: content,
            upvotes: 0,
            downvotes: 0,
            timestamp: Date(),
            type: type
        )

        debates[index].arguments.append(argument)
    }

    func vote(on argumentId: UUID, in debateId: UUID, isUpvote: Bool) {
        guard let debateIndex = debates.firstIndex(where: { $0.id == debateId }),
              let argIndex = debates[debateIndex].arguments.firstIndex(where: { $0.id == argumentId }) else { return }

        if isUpvote {
            debates[debateIndex].arguments[argIndex].upvotes += 1
        } else {
            debates[debateIndex].arguments[argIndex].downvotes += 1
        }
    }

    // MARK: - Evidence Library

    struct Evidence: Identifiable {
        let id: UUID
        let sourceURL: String
        let title: String
        let credibility: Credibility
        let tags: [String]
        var communityRating: Double

        enum Credibility: Int {
            case peerReviewed = 5
            case newsArticle = 3
            case blog = 2
            case anecdote = 1
        }
    }

    func submitEvidence(url: String, title: String, credibility: Evidence.Credibility) -> Evidence {
        let evidence = Evidence(id: UUID(), sourceURL: url, title: title, credibility: credibility, tags: [], communityRating: 0)
        evidenceLibrary.append(evidence)
        return evidence
    }

    // MARK: - Belief Tracking

    struct BeliefUpdate: Identifiable {
        let id: UUID
        let beliefId: UUID
        let previousStrength: Int
        let newStrength: Int
        let reason: UpdateReason
        let date: Date

        enum UpdateReason: String {
            case newEvidence = "New evidence"
            case debateChange = "Debate changed my mind"
            case personalGrowth = "Personal growth"
        }
    }

    func trackBeliefUpdate(beliefId: UUID, previousStrength: Int, newStrength: Int, reason: BeliefUpdate.UpdateReason) {
        // Track in history
    }
}
