import Foundation
import Combine

@MainActor
final class BeliefDetailViewModel: ObservableObject {
    @Published var belief: Belief
    @Published var showingAddEvidence = false
    @Published var showingStressTest = false

    private let databaseService = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init(belief: Belief) {
        self.belief = belief
    }

    func refresh() {
        if let updated = databaseService.allBeliefs.first(where: { $0.id == belief.id }) {
            belief = updated
        }
    }

    func addEvidence(text: String, type: EvidenceType) {
        let evidence = Evidence(beliefId: belief.id, text: text, type: type)
        databaseService.addEvidence(evidence)
        refresh()
    }

    func deleteEvidence(_ item: Evidence) {
        databaseService.deleteEvidence(item)
        refresh()
    }

    func deleteBelief() {
        databaseService.deleteBelief(belief)
    }

    var supportingEvidence: [Evidence] {
        belief.evidenceItems.filter { $0.type == .support }
    }

    var contradictingEvidence: [Evidence] {
        belief.evidenceItems.filter { $0.type == .contradict }
    }
}
