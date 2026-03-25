import Foundation

struct BeliefConnection: Identifiable, Equatable {
    let id: UUID
    let fromBeliefId: UUID
    let toBeliefId: UUID
    var strength: Double

    init(id: UUID = UUID(), fromBeliefId: UUID, toBeliefId: UUID, strength: Double = 0.5) {
        self.id = id
        self.fromBeliefId = fromBeliefId
        self.toBeliefId = toBeliefId
        self.strength = strength
    }
}
