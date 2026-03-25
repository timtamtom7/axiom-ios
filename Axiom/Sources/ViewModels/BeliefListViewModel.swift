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

    func deleteBelief(_ belief: Belief) {
        databaseService.deleteBelief(belief)
    }

    func addBelief(text: String) {
        let belief = Belief(text: text)
        databaseService.addBelief(belief)
    }
}
