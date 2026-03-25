import Foundation
import SQLite

@MainActor
final class DatabaseService: ObservableObject {
    static let shared = DatabaseService()

    private var db: Connection?

    // Tables
    private let beliefs = Table("beliefs")
    private let evidence = Table("evidence")
    private let connections = Table("connections")
    private let checkpoints = Table("checkpoints")

    // Belief columns
    private let id = SQLite.Expression<String>("id")
    private let text = SQLite.Expression<String>("text")
    private let createdAt = SQLite.Expression<Date>("created_at")
    private let updatedAt = SQLite.Expression<Date>("updated_at")

    // Belief extended columns
    private let isCore = SQLite.Expression<Bool>("is_core")
    private let rootCause = SQLite.Expression<String?>("root_cause")
    private let derivedFrom = SQLite.Expression<String?>("derived_from")
    private let checkInScheduledAt = SQLite.Expression<Date?>("checkin_scheduled_at")
    private let checkInIntervalDays = SQLite.Expression<Int?>("checkin_interval_days")
    private let isArchived = SQLite.Expression<Bool>("is_archived")
    private let archivedAt = SQLite.Expression<Date?>("archived_at")
    private let archiveReason = SQLite.Expression<String?>("archive_reason")
    private let archivedScore = SQLite.Expression<Double?>("archived_score")

    // Evidence columns
    private let evidenceId = SQLite.Expression<String>("id")
    private let evidenceBeliefId = SQLite.Expression<String>("belief_id")
    private let evidenceText = SQLite.Expression<String>("text")
    private let evidenceType = SQLite.Expression<String>("type")
    private let evidenceCreatedAt = SQLite.Expression<Date>("created_at")
    private let evidenceConfidence = SQLite.Expression<Double>("confidence")
    private let sourceURL = SQLite.Expression<String?>("source_url")
    private let sourceLabel = SQLite.Expression<String?>("source_label")
    private let attachmentPath = SQLite.Expression<String?>("attachment_path")
    private let attachmentType = SQLite.Expression<String?>("attachment_type")

    // Connection columns
    private let connId = SQLite.Expression<String>("id")
    private let connFromId = SQLite.Expression<String>("from_belief_id")
    private let connToId = SQLite.Expression<String>("to_belief_id")
    private let connStrength = SQLite.Expression<Double>("strength")

    // Checkpoint columns
    private let checkpointId = SQLite.Expression<String>("id")
    private let checkpointBeliefId = SQLite.Expression<String>("belief_id")
    private let checkpointRecordedAt = SQLite.Expression<Date>("recorded_at")
    private let checkpointScore = SQLite.Expression<Double>("score")
    private let checkpointNote = SQLite.Expression<String?>("note")

    @Published var allBeliefs: [Belief] = []
    @Published var archivedBeliefs: [Belief] = []
    @Published var allConnections: [BeliefConnection] = []

    private init() {
        setupDatabase()
        loadBeliefs()
        loadConnections()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("axiom.sqlite3")
            db = try Connection(path.path)
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        // Beliefs — add new columns if missing
        try db?.run(beliefs.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(text)
            t.column(createdAt)
            t.column(updatedAt)
            t.column(isCore, defaultValue: false)
            t.column(rootCause)
            t.column(derivedFrom)
            t.column(checkInScheduledAt)
            t.column(checkInIntervalDays)
            t.column(isArchived, defaultValue: false)
            t.column(archivedAt)
            t.column(archiveReason)
            t.column(archivedScore)
        })

        try db?.run(evidence.create(ifNotExists: true) { t in
            t.column(evidenceId, primaryKey: true)
            t.column(evidenceBeliefId)
            t.column(evidenceText)
            t.column(evidenceType)
            t.column(evidenceCreatedAt)
            t.column(evidenceConfidence, defaultValue: 0.7)
            t.column(sourceURL)
            t.column(sourceLabel)
            t.column(attachmentPath)
            t.column(attachmentType)
        })

        try db?.run(connections.create(ifNotExists: true) { t in
            t.column(connId, primaryKey: true)
            t.column(connFromId)
            t.column(connToId)
            t.column(connStrength)
        })

        try db?.run(checkpoints.create(ifNotExists: true) { t in
            t.column(checkpointId, primaryKey: true)
            t.column(checkpointBeliefId)
            t.column(checkpointRecordedAt)
            t.column(checkpointScore)
            t.column(checkpointNote)
        })

        // Migration: add missing columns to existing tables
        migrateBeliefsTable()
        migrateEvidenceTable()
    }

    private func migrateBeliefsTable() {
        guard let db = db else { return }
        do {
            // Add columns if they don't exist (SQLite without ALTER TABLE ADD COLUMN if not exists workaround via PRAGMA)
            let cols = try db.prepare("PRAGMA table_info(beliefs)").compactMap { $0[1] as? String }
            if !cols.contains("is_core") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN is_core INTEGER DEFAULT 0")
            }
            if !cols.contains("root_cause") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN root_cause TEXT")
            }
            if !cols.contains("derived_from") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN derived_from TEXT")
            }
            if !cols.contains("checkin_scheduled_at") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN checkin_scheduled_at TEXT")
            }
            if !cols.contains("checkin_interval_days") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN checkin_interval_days INTEGER")
            }
            if !cols.contains("is_archived") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN is_archived INTEGER DEFAULT 0")
            }
            if !cols.contains("archived_at") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN archived_at TEXT")
            }
            if !cols.contains("archive_reason") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN archive_reason TEXT")
            }
            if !cols.contains("archived_score") {
                try db.execute("ALTER TABLE beliefs ADD COLUMN archived_score REAL")
            }
        } catch {
            print("Migration error: \(error)")
        }
    }

    private func migrateEvidenceTable() {
        guard let db = db else { return }
        do {
            let cols = try db.prepare("PRAGMA table_info(evidence)").compactMap { $0[1] as? String }
            if !cols.contains("confidence") {
                try db.execute("ALTER TABLE evidence ADD COLUMN confidence REAL DEFAULT 0.7")
            }
            if !cols.contains("source_url") {
                try db.execute("ALTER TABLE evidence ADD COLUMN source_url TEXT")
            }
            if !cols.contains("source_label") {
                try db.execute("ALTER TABLE evidence ADD COLUMN source_label TEXT")
            }
            if !cols.contains("attachment_path") {
                try db.execute("ALTER TABLE evidence ADD COLUMN attachment_path TEXT")
            }
            if !cols.contains("attachment_type") {
                try db.execute("ALTER TABLE evidence ADD COLUMN attachment_type TEXT")
            }
        } catch {
            print("Evidence migration error: \(error)")
        }
    }

    // MARK: - Belief CRUD

    func loadBeliefs() {
        guard let db = db else { return }
        do {
            var loaded: [Belief] = []
            for row in try db.prepare(beliefs.filter(isArchived == false)) {
                guard let beliefId = UUID(uuidString: row[id]) else { continue }
                let beliefEvidence = loadEvidence(for: beliefId)
                let belief = Belief(
                    id: beliefId,
                    text: row[text],
                    createdAt: row[createdAt],
                    updatedAt: row[updatedAt],
                    evidenceItems: beliefEvidence,
                    isCore: row[isCore],
                    rootCause: row[rootCause],
                    derivedFrom: row[derivedFrom].flatMap { UUID(uuidString: $0) },
                    checkInScheduledAt: row[checkInScheduledAt],
                    checkInIntervalDays: row[checkInIntervalDays],
                    isArchived: row[isArchived],
                    archivedAt: row[archivedAt],
                    archiveReason: row[archiveReason],
                    archivedScore: row[archivedScore]
                )
                loaded.append(belief)
            }
            allBeliefs = loaded.sorted { $0.updatedAt > $1.updatedAt }
            loadArchivedBeliefs()
        } catch {
            print("Load beliefs error: \(error)")
        }
    }

    private func loadArchivedBeliefs() {
        guard let db = db else { return }
        do {
            var loaded: [Belief] = []
            for row in try db.prepare(beliefs.filter(isArchived == true)) {
                guard let beliefId = UUID(uuidString: row[id]) else { continue }
                let beliefEvidence = loadEvidence(for: beliefId)
                let belief = Belief(
                    id: beliefId,
                    text: row[text],
                    createdAt: row[createdAt],
                    updatedAt: row[updatedAt],
                    evidenceItems: beliefEvidence,
                    isCore: row[isCore],
                    rootCause: row[rootCause],
                    derivedFrom: row[derivedFrom].flatMap { UUID(uuidString: $0) },
                    checkInScheduledAt: row[checkInScheduledAt],
                    checkInIntervalDays: row[checkInIntervalDays],
                    isArchived: row[isArchived],
                    archivedAt: row[archivedAt],
                    archiveReason: row[archiveReason],
                    archivedScore: row[archivedScore]
                )
                loaded.append(belief)
            }
            archivedBeliefs = loaded.sorted { ($0.archivedAt ?? Date.distantPast) > ($1.archivedAt ?? Date.distantPast) }
        } catch {
            print("Load archived beliefs error: \(error)")
        }
    }

    func addBelief(_ belief: Belief) {
        guard let db = db else { return }
        do {
            try db.run(beliefs.insert(
                id <- belief.id.uuidString,
                text <- belief.text,
                createdAt <- belief.createdAt,
                updatedAt <- belief.updatedAt,
                isCore <- belief.isCore,
                rootCause <- belief.rootCause,
                derivedFrom <- belief.derivedFrom?.uuidString,
                checkInScheduledAt <- belief.checkInScheduledAt,
                checkInIntervalDays <- belief.checkInIntervalDays,
                isArchived <- belief.isArchived,
                archivedAt <- belief.archivedAt,
                archiveReason <- belief.archiveReason,
                archivedScore <- belief.archivedScore
            ))
            loadBeliefs()
        } catch {
            print("Add belief error: \(error)")
        }
    }

    func updateBelief(_ belief: Belief) {
        guard let db = db else { return }
        let target = beliefs.filter(id == belief.id.uuidString)
        do {
            try db.run(target.update(
                text <- belief.text,
                updatedAt <- Date(),
                isCore <- belief.isCore,
                rootCause <- belief.rootCause,
                derivedFrom <- belief.derivedFrom?.uuidString,
                checkInScheduledAt <- belief.checkInScheduledAt,
                checkInIntervalDays <- belief.checkInIntervalDays,
                isArchived <- belief.isArchived,
                archivedAt <- belief.archivedAt,
                archiveReason <- belief.archiveReason,
                archivedScore <- belief.archivedScore
            ))
            loadBeliefs()
        } catch {
            print("Update belief error: \(error)")
        }
    }

    func deleteBelief(_ belief: Belief) {
        guard let db = db else { return }
        let target = beliefs.filter(id == belief.id.uuidString)
        do {
            let evidenceTarget = evidence.filter(evidenceBeliefId == belief.id.uuidString)
            try db.run(evidenceTarget.delete())
            let connFrom = connections.filter(connFromId == belief.id.uuidString)
            let connTo = connections.filter(connToId == belief.id.uuidString)
            try db.run(connFrom.delete())
            try db.run(connTo.delete())
            let checkpointTarget = checkpoints.filter(checkpointBeliefId == belief.id.uuidString)
            try db.run(checkpointTarget.delete())
            try db.run(target.delete())
            loadBeliefs()
            loadConnections()
        } catch {
            print("Delete belief error: \(error)")
        }
    }

    func archiveBelief(_ belief: Belief, reason: String) {
        guard let db = db else { return }
        let target = beliefs.filter(id == belief.id.uuidString)
        do {
            try db.run(target.update(
                isArchived <- true,
                archivedAt <- Date(),
                archiveReason <- reason,
                archivedScore <- belief.score,
                updatedAt <- Date()
            ))
            loadBeliefs()
        } catch {
            print("Archive belief error: \(error)")
        }
    }

    // MARK: - Evidence CRUD

    private func loadEvidence(for beliefId: UUID) -> [Evidence] {
        guard let db = db else { return [] }
        var items: [Evidence] = []
        do {
            let query = evidence.filter(evidenceBeliefId == beliefId.uuidString)
            for row in try db.prepare(query) {
                guard let evId = UUID(uuidString: row[evidenceId]),
                      let evBeliefId = UUID(uuidString: row[evidenceBeliefId]) else { continue }
                let ev = Evidence(
                    id: evId,
                    beliefId: evBeliefId,
                    text: row[evidenceText],
                    type: EvidenceType(rawValue: row[evidenceType]) ?? .support,
                    createdAt: row[evidenceCreatedAt],
                    confidence: row[evidenceConfidence],
                    sourceURL: row[sourceURL],
                    sourceLabel: row[sourceLabel],
                    attachmentPath: row[attachmentPath],
                    attachmentType: row[attachmentType].flatMap { AttachmentType(rawValue: $0) }
                )
                items.append(ev)
            }
        } catch {
            print("Load evidence error: \(error)")
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func addEvidence(_ item: Evidence) {
        guard let db = db else { return }
        do {
            try db.run(evidence.insert(
                evidenceId <- item.id.uuidString,
                evidenceBeliefId <- item.beliefId.uuidString,
                evidenceText <- item.text,
                evidenceType <- item.type.rawValue,
                evidenceCreatedAt <- item.createdAt,
                evidenceConfidence <- item.confidence,
                sourceURL <- item.sourceURL,
                sourceLabel <- item.sourceLabel,
                attachmentPath <- item.attachmentPath,
                attachmentType <- item.attachmentType?.rawValue
            ))
            let target = beliefs.filter(id == item.beliefId.uuidString)
            try db.run(target.update(updatedAt <- Date()))
            loadBeliefs()
        } catch {
            print("Add evidence error: \(error)")
        }
    }

    func deleteEvidence(_ item: Evidence) {
        guard let db = db else { return }
        let target = evidence.filter(evidenceId == item.id.uuidString)
        do {
            try db.run(target.delete())
            let beliefTarget = beliefs.filter(id == item.beliefId.uuidString)
            try db.run(beliefTarget.update(updatedAt <- Date()))
            loadBeliefs()
        } catch {
            print("Delete evidence error: \(error)")
        }
    }

    // MARK: - Connection CRUD

    func loadConnections() {
        guard let db = db else { return }
        do {
            var loaded: [BeliefConnection] = []
            for row in try db.prepare(connections) {
                guard let cId = UUID(uuidString: row[connId]),
                      let cFrom = UUID(uuidString: row[connFromId]),
                      let cTo = UUID(uuidString: row[connToId]) else { continue }
                let conn = BeliefConnection(
                    id: cId,
                    fromBeliefId: cFrom,
                    toBeliefId: cTo,
                    strength: row[connStrength]
                )
                loaded.append(conn)
            }
            allConnections = loaded
        } catch {
            print("Load connections error: \(error)")
        }
    }

    func addConnection(_ connection: BeliefConnection) {
        guard let db = db else { return }
        do {
            try db.run(connections.insert(
                connId <- connection.id.uuidString,
                connFromId <- connection.fromBeliefId.uuidString,
                connToId <- connection.toBeliefId.uuidString,
                connStrength <- connection.strength
            ))
            loadConnections()
        } catch {
            print("Add connection error: \(error)")
        }
    }

    func deleteConnection(_ connection: BeliefConnection) {
        guard let db = db else { return }
        let target = connections.filter(connId == connection.id.uuidString)
        do {
            try db.run(target.delete())
            loadConnections()
        } catch {
            print("Delete connection error: \(error)")
        }
    }

    func connectionsFor(beliefId: UUID) -> [BeliefConnection] {
        allConnections.filter { $0.fromBeliefId == beliefId || $0.toBeliefId == beliefId }
    }

    // MARK: - Checkpoint CRUD

    func checkpointsFor(beliefId: UUID) -> [BeliefCheckpoint] {
        guard let db = db else { return [] }
        var items: [BeliefCheckpoint] = []
        do {
            let query = checkpoints.filter(checkpointBeliefId == beliefId.uuidString)
            for row in try db.prepare(query) {
                guard let cpId = UUID(uuidString: row[checkpointId]),
                      let cpBeliefId = UUID(uuidString: row[checkpointBeliefId]) else { continue }
                let cp = BeliefCheckpoint(
                    id: cpId,
                    beliefId: cpBeliefId,
                    recordedAt: row[checkpointRecordedAt],
                    score: row[checkpointScore],
                    note: row[checkpointNote]
                )
                items.append(cp)
            }
        } catch {
            print("Load checkpoints error: \(error)")
        }
        return items.sorted { $0.recordedAt > $1.recordedAt }
    }

    func addCheckpoint(_ checkpoint: BeliefCheckpoint) {
        guard let db = db else { return }
        do {
            try db.run(checkpoints.insert(
                checkpointId <- checkpoint.id.uuidString,
                checkpointBeliefId <- checkpoint.beliefId.uuidString,
                checkpointRecordedAt <- checkpoint.recordedAt,
                checkpointScore <- checkpoint.score,
                checkpointNote <- checkpoint.note
            ))
        } catch {
            print("Add checkpoint error: \(error)")
        }
    }
}
