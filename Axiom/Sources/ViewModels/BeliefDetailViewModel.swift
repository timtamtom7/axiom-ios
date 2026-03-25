import Foundation
import Combine

@MainActor
final class BeliefDetailViewModel: ObservableObject {
    @Published var belief: Belief
    @Published var showingAddEvidence = false
    @Published var showingStressTest = false
    @Published var showingDeepDive = false
    @Published var showingConnections = false
    @Published var showingCheckIn = false
    @Published var showingEvolution = false
    @Published var checkpoints: [BeliefCheckpoint] = []

    private let databaseService = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init(belief: Belief) {
        self.belief = belief
        loadCheckpoints()
    }

    func refresh() {
        if let updated = databaseService.allBeliefs.first(where: { $0.id == belief.id }) {
            belief = updated
            loadCheckpoints()
        }
    }

    func loadCheckpoints() {
        checkpoints = databaseService.checkpointsFor(beliefId: belief.id)
    }

    func addEvidence(text: String, type: EvidenceType, confidence: Double = 0.7, sourceURL: String? = nil, sourceLabel: String? = nil) {
        let evidence = Evidence(
            beliefId: belief.id,
            text: text,
            type: type,
            confidence: confidence,
            sourceURL: sourceURL,
            sourceLabel: sourceLabel
        )
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

    func archiveBelief(reason: String) {
        databaseService.archiveBelief(belief, reason: reason)
    }

    func updateBelief(text: String, isCore: Bool, rootCause: String?) {
        belief.text = text
        belief.isCore = isCore
        belief.rootCause = rootCause
        databaseService.updateBelief(belief)
        refresh()
    }

    func toggleCore() {
        belief.isCore.toggle()
        databaseService.updateBelief(belief)
        refresh()
    }

    func scheduleCheckIn(days: Int) {
        belief.scheduleCheckIn(days: days)
        databaseService.updateBelief(belief)
        refresh()
    }

    func recordCheckpoint(note: String?) {
        let checkpoint = BeliefCheckpoint(
            beliefId: belief.id,
            score: belief.score,
            note: note
        )
        databaseService.addCheckpoint(checkpoint)
        loadCheckpoints()
    }

    // MARK: - Connections

    var connections: [BeliefConnection] {
        databaseService.connectionsFor(beliefId: belief.id)
    }

    var connectedBeliefs: [Belief] {
        let conns = connections
        return conns.compactMap { conn in
            let otherId = conn.fromBeliefId == belief.id ? conn.toBeliefId : conn.fromBeliefId
            return databaseService.allBeliefs.first { $0.id == otherId }
        }
    }

    func addConnection(to otherBelief: Belief, strength: Double = 0.5) {
        // Don't duplicate
        guard !connections.contains(where: { $0.toBeliefId == otherBelief.id || $0.fromBeliefId == otherBelief.id }) else { return }
        let conn = BeliefConnection(fromBeliefId: belief.id, toBeliefId: otherBelief.id, strength: strength)
        databaseService.addConnection(conn)
        objectWillChange.send()
    }

    func removeConnection(_ conn: BeliefConnection) {
        databaseService.deleteConnection(conn)
        objectWillChange.send()
    }

    var supportingEvidence: [Evidence] {
        belief.evidenceItems.filter { $0.type == .support }
    }

    var contradictingEvidence: [Evidence] {
        belief.evidenceItems.filter { $0.type == .contradict }
    }
}
