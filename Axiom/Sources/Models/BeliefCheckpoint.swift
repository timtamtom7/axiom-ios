import Foundation

/// Records a snapshot of a belief's state at a point in time for outcome tracking.
struct BeliefCheckpoint: Identifiable, Equatable {
    let id: UUID
    let beliefId: UUID
    let recordedAt: Date
    let score: Double
    let note: String?

    init(
        id: UUID = UUID(),
        beliefId: UUID,
        recordedAt: Date = Date(),
        score: Double,
        note: String? = nil
    ) {
        self.id = id
        self.beliefId = beliefId
        self.recordedAt = recordedAt
        self.score = score
        self.note = note
    }
}
