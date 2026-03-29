import Foundation
import Combine
import SwiftUI

final class DataService: ObservableObject {
    nonisolated(unsafe) static let shared = DataService()

    @Published var beliefs: [Belief] = []
    @Published var streak: Int = 7
    @Published var lastCheckIn: Date = Date()

    private init() {
        loadSampleData()
    }

    private func loadSampleData() {
        let b1 = Belief(text: "I am capable of learning anything I set my mind to", score: 78, isCore: true, evidenceItems: [
            Evidence(beliefId: UUID(), text: "Learned Swift in 3 months", type: .support),
            Evidence(beliefId: UUID(), text: "Struggled with calculus in college", type: .contradict)
        ])
        let b2 = Belief(text: "I am a good friend", score: 85, isCore: true, evidenceItems: [
            Evidence(beliefId: UUID(), text: "Stayed up all night helping a friend in crisis", type: .support),
            Evidence(beliefId: UUID(), text: "Sometimes forget to check in", type: .contradict)
        ])
        let b3 = Belief(text: "I should always put others first", score: 35, isCore: false, evidenceItems: [
            Evidence(beliefId: UUID(), text: "Compromise my own needs often", type: .support),
            Evidence(beliefId: UUID(), text: "Setting boundaries improves my relationships", type: .contradict)
        ])
        beliefs = [b1, b2, b3]
    }

    func addBelief(_ text: String, isCore: Bool = false) {
        let belief = Belief(text: text, isCore: isCore)
        beliefs.append(belief)
    }

    func updateScore(for beliefId: UUID) {
        guard let idx = beliefs.firstIndex(where: { $0.id == beliefId }) else { return }
        let b = beliefs[idx]
        let supporting = b.evidenceItems.filter { $0.type == .support }.count
        let contradicting = b.evidenceItems.filter { $0.type == .contradict }.count
        let score = Double(supporting + 1) / Double(supporting + contradicting + 2) * 100
        beliefs[idx].score = min(100, max(0, score))
        beliefs[idx].updatedAt = Date()
    }

    func addEvidence(to beliefId: UUID, text: String, type: EvidenceType) {
        guard let idx = beliefs.firstIndex(where: { $0.id == beliefId }) else { return }
        let ev = Evidence(beliefId: beliefId, text: text, type: type)
        beliefs[idx].evidenceItems.append(ev)
        updateScore(for: beliefId)
    }

    func deleteEvidence(beliefId: UUID, evidenceId: UUID) {
        guard let idx = beliefs.firstIndex(where: { $0.id == beliefId }) else { return }
        beliefs[idx].evidenceItems.removeAll { $0.id == evidenceId }
        updateScore(for: beliefId)
    }

    func checkIn() {
        lastCheckIn = Date()
        streak = min(streak + 1, 365)
    }
}
