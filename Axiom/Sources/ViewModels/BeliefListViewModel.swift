import Foundation
import Combine

@MainActor
final class BeliefListViewModel: ObservableObject {
    @Published var beliefs: [Belief] = []
    @Published var searchText = ""

    private var cancellables = Set<AnyCancellable>()
    private let databaseService = DatabaseService.shared

    init() {
        databaseService.$allBeliefs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] beliefs in
                self?.beliefs = beliefs
            }
            .store(in: &cancellables)
    }

    var filteredBeliefs: [Belief] {
        if searchText.isEmpty {
            return beliefs
        }
        return beliefs.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var archivedBeliefs: [Belief] {
        databaseService.archivedBeliefs
    }

    var beliefsDueForCheckIn: [Belief] {
        let now = Date()
        return beliefs.filter { belief in
            guard let scheduled = belief.checkInScheduledAt else { return false }
            return scheduled <= now
        }
    }

    func connectionCount(for beliefId: UUID) -> Int {
        databaseService.connectionsFor(beliefId: beliefId).count
    }

    func deleteBelief(_ belief: Belief) {
        databaseService.deleteBelief(belief)
    }

    func addBelief(text: String, isCore: Bool = false, rootCause: String? = nil) {
        let belief = Belief(text: text, isCore: isCore, rootCause: rootCause)
        databaseService.addBelief(belief)
    }
}
