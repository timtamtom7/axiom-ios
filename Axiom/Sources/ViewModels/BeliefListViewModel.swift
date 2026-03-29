import Foundation
import Combine

@MainActor
final class BeliefListViewModel: ObservableObject {
    @Published var beliefs: [Belief] = []
    @Published var searchText = ""

    private var cancellables = Set<AnyCancellable>()
    private let databaseService = DatabaseService.shared

    /// Debounced search text to avoid filtering on every keystroke (R25)
    @Published private var debouncedSearchText = ""
    private var searchDebounceTask: Task<Void, Never>?

    /// In-memory belief history capped at 1000 entries to limit memory usage (R25)
    private static let maxHistorySize = 1000

    init() {
        databaseService.$allBeliefs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] beliefs in
                self?.beliefs = beliefs
            }
            .store(in: &cancellables)

        // R25: Debounce search input by 300ms to avoid UI stutter
        $searchText
            .dropFirst()
            .sink { [weak self] text in
                self?.searchDebounceTask?.cancel()
                self?.searchDebounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    self?.debouncedSearchText = text
                }
            }
            .store(in: &cancellables)
    }

    var filteredBeliefs: [Belief] {
        if debouncedSearchText.isEmpty {
            return beliefs
        }
        return beliefs.filter {
            $0.text.localizedCaseInsensitiveContains(debouncedSearchText)
        }
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
