import Foundation

struct Evidence: Identifiable, Equatable, Hashable {
    let id: UUID
    let beliefId: UUID
    var text: String
    var type: EvidenceType
    var createdAt: Date

    init(id: UUID = UUID(), beliefId: UUID, text: String, type: EvidenceType, createdAt: Date = Date()) {
        self.id = id
        self.beliefId = beliefId
        self.text = text
        self.type = type
        self.createdAt = createdAt
    }
}

enum EvidenceType: String, CaseIterable {
    case support
    case contradict

    var displayName: String {
        switch self {
        case .support: return "Supporting"
        case .contradict: return "Contradicting"
        }
    }

    var icon: String {
        switch self {
        case .support: return "checkmark.circle.fill"
        case .contradict: return "xmark.circle.fill"
        }
    }
}
