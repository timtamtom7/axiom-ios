import Foundation

// MARK: - Therapist Models

struct TherapistCode: Codable {
    let code: String
    let therapistId: UUID
    let expiresAt: Date
    let createdAt: Date
}

struct TherapistConnection: Codable, Identifiable {
    let id: UUID
    let therapistId: UUID
    let therapistName: String
    let connectedAt: Date
    let lastSyncAt: Date?
    var isActive: Bool
}

struct ProgressReport: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let therapistId: UUID
    let generatedAt: Date
    let periodStart: Date
    let periodEnd: Date
    let beliefCount: Int
    let evidenceCount: Int
    let averageScore: Double
    let scoreTrend: ScoreTrend
    let topDistortions: [CognitiveDistortion]
    let completionRate: Double

    enum ScoreTrend: String, Codable {
        case improving, stable, declining
    }
}

struct TherapistNote: Codable, Identifiable {
    let id: UUID
    let therapistId: UUID
    let clientId: UUID
    let beliefId: UUID?
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let type: NoteType

    enum NoteType: String, Codable {
        case annotation
        case assignment
        case sessionNote
        case general
    }
}

struct TherapistAssignment: Codable, Identifiable {
    let id: UUID
    let therapistId: UUID
    let clientId: UUID
    let exerciseId: UUID
    let assignedAt: Date
    let dueDate: Date?
    var isCompleted: Bool
    let completedAt: Date?
}

// MARK: - Therapist Service

/// R12: Therapist integration for progress sharing and guided support
final class TherapistService {
    static let shared = TherapistService()

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let connectionKey = "axiom.therapist.connection"
    private let notesKey = "axiom.therapist.notes"
    private let assignmentsKey = "axiom.therapist.assignments"

    private init() {}

    // MARK: - Connection

    /// Connect with a therapist using a share code
    func connectWithTherapist(code: String) async throws {
        // Simulate network delay for therapist lookup
        try await Task.sleep(nanoseconds: 500_000_000)

        guard !code.isEmpty else {
            throw TherapistError.invalidCode
        }

        // Parse the code (format: TH-{therapistId}-{timestamp})
        let components = code.split(separator: "-")
        guard components.count >= 2,
              let therapistId = UUID(uuidString: String(components[1])) else {
            throw TherapistError.invalidCode
        }

        let connection = TherapistConnection(
            id: UUID(),
            therapistId: therapistId,
            therapistName: "Dr. Therapist", // Would come from actual service
            connectedAt: Date(),
            lastSyncAt: nil,
            isActive: true
        )

        var connections = getConnections()
        connections.append(connection)
        saveConnections(connections)
    }

    /// Disconnect from a therapist
    func disconnectFromTherapist(therapistId: UUID) {
        var connections = getConnections()
        connections.removeAll { $0.therapistId == therapistId }
        saveConnections(connections)
    }

    /// Get all active therapist connections
    func getActiveConnections() -> [TherapistConnection] {
        return getConnections()
    }

    // MARK: - Progress Sharing

    /// Generate and share a progress report with the therapist
    func shareProgressWithTherapist(userId: UUID) -> ProgressReport {
        let beliefs = DataService.shared.getBeliefs()
        let evidence = beliefs.flatMap { $0.evidenceItems }

        let avgScore = beliefs.isEmpty ? 50.0 : beliefs.reduce(0) { $0 + $1.score } / Double(beliefs.count)

        let trend: ProgressReport.ScoreTrend
        if avgScore > 60 {
            trend = .improving
        } else if avgScore < 40 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Detect top distortions from recent beliefs
        let topDistortions: [CognitiveDistortion] = AIBeliefService.shared
            .analyzeBelief(beliefs.first ?? Belief(text: ""))
            .distortions

        return ProgressReport(
            id: UUID(),
            userId: userId,
            therapistId: UUID(), // Would be the connected therapist
            generatedAt: Date(),
            periodStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            periodEnd: Date(),
            beliefCount: beliefs.count,
            evidenceCount: evidence.count,
            averageScore: avgScore,
            scoreTrend: trend,
            topDistortions: Array(topDistortions.prefix(3)),
            completionRate: calculateExerciseCompletionRate()
        )
    }

    // MARK: - Therapist Notes

    /// Retrieve therapist notes for a user
    func getTherapistNotes(userId: UUID) -> [TherapistNote] {
        guard let data = userDefaults.data(forKey: notesKey),
              let notes = try? decoder.decode([TherapistNote].self, from: data) else {
            return []
        }
        return notes.filter { $0.clientId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Add a note from therapist (simulated — would come from secure channel)
    func addTherapistNote(_ note: TherapistNote) {
        var notes = getTherapistNotes(userId: note.clientId)
        notes.append(note)
        saveNotes(notes)
    }

    // MARK: - Assignments

    /// Get exercises assigned by therapist
    func getAssignments(userId: UUID) -> [TherapistAssignment] {
        guard let data = userDefaults.data(forKey: assignmentsKey),
              let assignments = try? decoder.decode([TherapistAssignment].self, from: data) else {
            return []
        }
        return assignments.filter { $0.clientId == userId }
    }

    /// Mark assignment as completed
    func completeAssignment(assignmentId: UUID) {
        guard let data = userDefaults.data(forKey: assignmentsKey),
              var assignments = try? decoder.decode([TherapistAssignment].self, from: data) else {
            return
        }

        if let index = assignments.firstIndex(where: { $0.id == assignmentId }) {
            assignments[index].isCompleted = true
            saveAssignments(assignments)
        }
    }

    // MARK: - Session Prep

    /// Generate a session prep report for upcoming therapy session
    func generateSessionPrepReport(userId: UUID) -> SessionPrepReport {
        let beliefs = DataService.shared.getBeliefs()
        let progress = shareProgressWithTherapist(userId: userId)
        let notes = getTherapistNotes(userId: userId)

        return SessionPrepReport(
            id: UUID(),
            userId: userId,
            generatedAt: Date(),
            recentBeliefs: Array(beliefs.sorted { $0.updatedAt > $1.updatedAt }.prefix(5)),
            progressSummary: progress,
            outstandingAssignments: getAssignments(userId: userId).filter { !$0.isCompleted },
            therapistNotes: Array(notes.prefix(3))
        )
    }

    // MARK: - Private Helpers

    private func getConnections() -> [TherapistConnection] {
        guard let data = userDefaults.data(forKey: connectionKey),
              let connections = try? decoder.decode([TherapistConnection].self, from: data) else {
            return []
        }
        return connections
    }

    private func saveConnections(_ connections: [TherapistConnection]) {
        if let data = try? encoder.encode(connections) {
            userDefaults.set(data, forKey: connectionKey)
        }
    }

    private func saveNotes(_ notes: [TherapistNote]) {
        if let data = try? encoder.encode(notes) {
            userDefaults.set(data, forKey: notesKey)
        }
    }

    private func saveAssignments(_ assignments: [TherapistAssignment]) {
        if let data = try? encoder.encode(assignments) {
            userDefaults.set(data, forKey: assignmentsKey)
        }
    }

    private func calculateExerciseCompletionRate() -> Double {
        // Placeholder — would track actual exercise completions
        return 0.75
    }
}

// MARK: - Supporting Types

struct SessionPrepReport: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let generatedAt: Date
    let recentBeliefs: [Belief]
    let progressSummary: ProgressReport
    let outstandingAssignments: [TherapistAssignment]
    let therapistNotes: [TherapistNote]
}

enum TherapistError: LocalizedError {
    case invalidCode
    case notConnected
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid therapist code. Please check and try again."
        case .notConnected:
            return "You are not connected to a therapist."
        case .networkError:
            return "Unable to connect. Please check your connection."
        }
    }
}

// MARK: - String Extension

private extension String {
    func split(separator: Character) -> [String] {
        return self.split(separator: separator).map(String.init)
    }
}
