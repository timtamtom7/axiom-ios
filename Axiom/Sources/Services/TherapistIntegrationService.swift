import Foundation
import SwiftUI

/// R7: Therapist integration service
/// Allows therapists to connect with clients and review belief audits
@MainActor
final class TherapistIntegrationService: ObservableObject {
    static let shared = TherapistIntegrationService()

    @Published var connectedTherapist: TherapistProfile?
    @Published var pendingInvites: [TherapistInvite] = []
    @Published var sessionHistory: [TherapySession] = []
    @Published var isConnecting = false

    private let therapistKey = "connected_therapist"
    private let sessionsKey = "therapy_sessions"

    private init() {
        loadState()
    }

    // MARK: - Connection

    func requestConnection(therapistCode: String) async throws {
        isConnecting = true
        defer { isConnecting = false }

        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))

        // In production, this would verify against a therapist directory API
        let therapist = TherapistProfile(
            id: UUID(),
            name: "Dr. Sarah Chen",
            specialization: "CBT & Anxiety",
            licenseNumber: "PSY-28471",
            email: "s.chen@axiomtherapy.com",
            joinedAt: Date(),
            isVerified: true
        )

        connectedTherapist = therapist
        saveState()
    }

    func disconnect() {
        connectedTherapist = nil
        saveState()
    }

    // MARK: - Sharing

    /// Share a belief summary with the connected therapist
    func shareBeliefWithTherapist(_ belief: Belief) async throws {
        guard let therapist = connectedTherapist else {
            throw TherapistError.notConnected
        }

        // In production, this would send to a HIPAA-compliant API
        let shareRecord = TherapyShareRecord(
            id: UUID(),
            beliefId: belief.id,
            beliefText: belief.text,
            score: belief.score,
            evidenceSummary: belief.evidenceItems.map { $0.text },
            sharedAt: Date(),
            therapistId: therapist.id
        )

        // Store locally
        var history = sessionHistory
        history.insert(
            TherapySession(
                id: UUID(),
                therapistId: therapist.id,
                type: .beliefShared,
                date: Date(),
                beliefId: belief.id,
                notes: nil
            ),
            at: 0
        )
        sessionHistory = history
        saveState()

        print("Shared belief '\(belief.text)' with therapist \(therapist.name)")
    }

    /// Request a progress report from therapist
    func requestProgressReport() async throws -> String {
        guard let therapist = connectedTherapist else {
            throw TherapistError.notConnected
        }

        // Simulate generating report
        try await Task.sleep(for: .seconds(1))

        return """
        Progress Report — \(Date().formatted(date: .abbreviated, time: .omitted))
        Therapist: \(therapist.name)

        Belief Audit Engagement:
        - Total beliefs tracked: \(DatabaseService.shared.allBeliefs.count)
        - Average belief score: \(String(format: "%.0f", calculateAverageScore()))%
        - Evidence items collected: \(calculateTotalEvidence())

        Key Observations:
        - Beliefs in challenging range (<50%): \(countChallengingBeliefs())
        - Strongly supported beliefs (>70%): \(countSupportedBeliefs())

        Recommendations:
        - Continue evidence collection for beliefs below 50%
        - Consider AI stress tests on core beliefs
        - Share progress with your therapist regularly
        """
    }

    // MARK: - State

    private func saveState() {
        if let therapist = connectedTherapist,
           let encoded = try? JSONEncoder().encode(therapist) {
            UserDefaults.standard.set(encoded, forKey: therapistKey)
        } else {
            UserDefaults.standard.removeObject(forKey: therapistKey)
        }

        if let encoded = try? JSONEncoder().encode(sessionHistory) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: therapistKey),
           let therapist = try? JSONDecoder().decode(TherapistProfile.self, from: data) {
            connectedTherapist = therapist
        }

        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let history = try? JSONDecoder().decode([TherapySession].self, from: data) {
            sessionHistory = history
        }
    }

    // MARK: - Helpers

    private func calculateAverageScore() -> Double {
        let beliefs = DatabaseService.shared.allBeliefs
        guard !beliefs.isEmpty else { return 50 }
        return beliefs.reduce(0) { $0 + $1.score } / Double(beliefs.count)
    }

    private func calculateTotalEvidence() -> Int {
        DatabaseService.shared.allBeliefs.reduce(0) { $0 + $1.evidenceItems.count }
    }

    private func countChallengingBeliefs() -> Int {
        DatabaseService.shared.allBeliefs.filter { $0.score < 50 }.count
    }

    private func countSupportedBeliefs() -> Int {
        DatabaseService.shared.allBeliefs.filter { $0.score > 70 }.count
    }
}

// MARK: - Models

struct TherapistProfile: Identifiable, Codable {
    let id: UUID
    let name: String
    let specialization: String
    let licenseNumber: String
    let email: String
    let joinedAt: Date
    let isVerified: Bool
}

struct TherapistInvite: Identifiable, Codable {
    let id: UUID
    let therapistName: String
    let therapistEmail: String
    let invitedAt: Date
    var status: InviteStatus
}

enum InviteStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct TherapySession: Identifiable, Codable {
    let id: UUID
    let therapistId: UUID
    let type: SessionType
    let date: Date
    let beliefId: UUID?
    let notes: String?
}

enum SessionType: String, Codable {
    case beliefShared = "belief_shared"
    case reportGenerated = "report_generated"
    case checkIn = "check_in"
    case treatmentPlanUpdated = "treatment_plan_updated"
}

struct TherapyShareRecord: Identifiable, Codable {
    let id: UUID
    let beliefId: UUID
    let beliefText: String
    let score: Double
    let evidenceSummary: [String]
    let sharedAt: Date
    let therapistId: UUID
}

enum TherapistError: LocalizedError {
    case notConnected
    case invalidCode
    case networkError

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "No therapist connected. Go to Settings to connect."
        case .invalidCode:
            return "Invalid therapist code. Please check and try again."
        case .networkError:
            return "Could not connect to therapist. Check your connection."
        }
    }
}
