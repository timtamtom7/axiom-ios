import Foundation
import SwiftUI

/// Represents an anonymously shared belief with a shareable code
struct SharedBelief: Identifiable, Codable {
    let id: UUID
    let beliefText: String
    let isCore: Bool
    let score: Double
    let supportingCount: Int
    let contradictingCount: Int
    let sharedAt: Date
    let shareCode: String

    /// Creates a new shared belief from a belief
    init(from belief: Belief) {
        self.id = UUID()
        self.beliefText = belief.text
        self.isCore = belief.isCore
        self.score = belief.score
        self.supportingCount = belief.supportingCount
        self.contradictingCount = belief.contradictingCount
        self.sharedAt = Date()
        self.shareCode = SharedBelief.generateShareCode(for: belief)
    }

    init(id: UUID, beliefText: String, isCore: Bool, score: Double, supportingCount: Int, contradictingCount: Int, sharedAt: Date, shareCode: String) {
        self.id = id
        self.beliefText = beliefText
        self.isCore = isCore
        self.score = score
        self.supportingCount = supportingCount
        self.contradictingCount = contradictingCount
        self.sharedAt = sharedAt
        self.shareCode = shareCode
    }

    /// Generates a short shareable code (6 characters) from belief data
    static func generateShareCode(for belief: Belief) -> String {
        let raw = "\(belief.text):\(belief.isCore):\(Int(belief.score))"
        let data = Data(raw.utf8)
        let hash = data.withUnsafeBytes { bytes -> UInt64 in
            var h: UInt64 = 0xcbf29ce484222325
            for byte in bytes {
                h ^= UInt64(byte)
                h &*= 0x100000001b3
            }
            return h
        }
        let base36 = String(hash, radix: 36)
        return String(base36.prefix(6)).uppercased()
    }

    /// Attempts to parse a shared belief from a share code
    /// Returns nil if the code format is invalid
    static func parse(shareCode: String) -> (text: String, isCore: Bool, score: Int)? {
        let code = shareCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6, code.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return nil
        }
        return nil // Would query server in real implementation
    }
}

/// Stores community shared beliefs (simulated server-side)
@MainActor
final class CommunityStore: ObservableObject {
    static let shared = CommunityStore()

    private let userDefaultsKey = "community_beliefs"

    @Published var sharedBeliefs: [SharedBelief] = []

    init() {
        loadSharedBeliefs()
    }

    func loadSharedBeliefs() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SharedBelief].self, from: data) else {
            sharedBeliefs = sampleCommunityBeliefs
            return
        }
        sharedBeliefs = decoded
    }

    func addSharedBelief(_ belief: Belief) {
        let shared = SharedBelief(from: belief)
        sharedBeliefs.insert(shared, at: 0)
        save()
    }

    func removeSharedBelief(id: UUID) {
        sharedBeliefs.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(sharedBeliefs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Sample community beliefs for demonstration
    private var sampleCommunityBeliefs: [SharedBelief] {
        [
            SharedBelief(
                id: UUID(),
                beliefText: "Hard work is the key to success",
                isCore: true,
                score: 72,
                supportingCount: 8,
                contradictingCount: 3,
                sharedAt: Date().addingTimeInterval(-86400 * 3),
                shareCode: "K9X2M1"
            ),
            SharedBelief(
                id: UUID(),
                beliefText: "People are fundamentally trustworthy",
                isCore: false,
                score: 45,
                supportingCount: 5,
                contradictingCount: 7,
                sharedAt: Date().addingTimeInterval(-86400 * 7),
                shareCode: "P3L8N6"
            ),
            SharedBelief(
                id: UUID(),
                beliefText: "I must always be productive to have value",
                isCore: true,
                score: 28,
                supportingCount: 2,
                contradictingCount: 11,
                sharedAt: Date().addingTimeInterval(-86400 * 14),
                shareCode: "R7W2Q9"
            ),
            SharedBelief(
                id: UUID(),
                beliefText: "Emotional vulnerability is a sign of weakness",
                isCore: false,
                score: 35,
                supportingCount: 4,
                contradictingCount: 9,
                sharedAt: Date().addingTimeInterval(-86400 * 21),
                shareCode: "T4H6K8"
            )
        ]
    }
}

struct ShareCodeGenerator {
    /// Formats a shareable code for display
    static func formatDisplayCode(_ code: String) -> String {
        code.uppercased().enumerated().map { index, char in
            index > 0 && index % 3 == 0 ? " \(char)" : String(char)
        }.joined()
    }

    /// Creates a deep link URL for sharing
    static func createShareURL(code: String) -> URL? {
        URL(string: "axiom://belief/\(code)")
    }
}
