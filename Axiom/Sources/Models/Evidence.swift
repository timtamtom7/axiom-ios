import Foundation

struct Evidence: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: UUID
    let beliefId: UUID
    var text: String
    var type: EvidenceType
    var createdAt: Date
    var confidence: Double // 0.0 to 1.0
    var sourceURL: String?
    var sourceLabel: String?
    var attachmentPath: String? // Local path to photo/voice note
    var attachmentType: AttachmentType?

    init(
        id: UUID = UUID(),
        beliefId: UUID,
        text: String,
        type: EvidenceType,
        createdAt: Date = Date(),
        confidence: Double = 0.7,
        sourceURL: String? = nil,
        sourceLabel: String? = nil,
        attachmentPath: String? = nil,
        attachmentType: AttachmentType? = nil
    ) {
        self.id = id
        self.beliefId = beliefId
        self.text = text
        self.type = type
        self.createdAt = createdAt
        self.confidence = confidence
        self.sourceURL = sourceURL
        self.sourceLabel = sourceLabel
        self.attachmentPath = attachmentPath
        self.attachmentType = attachmentType
    }

    var confidenceLabel: String {
        if confidence >= 0.8 { return "High" }
        else if confidence >= 0.5 { return "Medium" }
        else { return "Low" }
    }
}

enum AttachmentType: String, CaseIterable, Codable {
    case photo
    case voiceNote
    case document

    var icon: String {
        switch self {
        case .photo: return "photo"
        case .voiceNote: return "waveform"
        case .document: return "doc.text"
        }
    }
}

enum EvidenceType: String, CaseIterable, Codable {
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
