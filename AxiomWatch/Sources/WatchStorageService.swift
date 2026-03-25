import Foundation

/// Lightweight storage for watchOS using UserDefaults.
/// Does not require SQLite - designed for simple belief check-in only.
@MainActor
final class WatchStorageService: ObservableObject {
    static let shared = WatchStorageService()

    private let defaults = UserDefaults.standard
    private let beliefsKey = "watch_beliefs"
    private let checkpointsKey = "watch_checkpoints"

    @Published var beliefs: [WatchBelief] = []

    init() {
        loadBeliefs()
    }

    func loadBeliefs() {
        guard let data = defaults.data(forKey: beliefsKey),
              let decoded = try? JSONDecoder().decode([WatchBelief].self, from: data) else {
            beliefs = []
            return
        }
        beliefs = decoded
    }

    func saveBeliefs() {
        if let encoded = try? JSONEncoder().encode(beliefs) {
            defaults.set(encoded, forKey: beliefsKey)
        }
    }

    func addCheckpoint(_ checkpoint: WatchCheckpoint) {
        var checkpoints = loadCheckpoints()
        checkpoints.append(checkpoint)
        if let encoded = try? JSONEncoder().encode(checkpoints) {
            defaults.set(encoded, forKey: checkpointsKey)
        }
    }

    func loadCheckpoints() -> [WatchCheckpoint] {
        guard let data = defaults.data(forKey: checkpointsKey),
              let decoded = try? JSONDecoder().decode([WatchCheckpoint].self, from: data) else {
            return []
        }
        return decoded
    }
}

struct WatchBelief: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCore: Bool
    var supportingCount: Int
    var contradictingCount: Int
    var score: Double

    init(from belief: Belief) {
        self.id = belief.id
        self.text = belief.text
        self.isCore = belief.isCore
        self.supportingCount = belief.supportingCount
        self.contradictingCount = belief.contradictingCount
        self.score = belief.score
    }
}

struct WatchCheckpoint: Identifiable, Codable {
    let id: UUID
    let beliefId: UUID
    let recordedAt: Date
    let score: Double
    let note: String?
}
