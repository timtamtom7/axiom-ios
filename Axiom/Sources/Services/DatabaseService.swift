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

    // Belief columns
    private let id = SQLite.Expression<String>("id")
    private let text = SQLite.Expression<String>("text")
    private let createdAt = SQLite.Expression<Date>("created_at")
    private let updatedAt = SQLite.Expression<Date>("updated_at")

    // Evidence columns
    private let evidenceId = SQLite.Expression<String>("id")
    private let evidenceBeliefId = SQLite.Expression<String>("belief_id")
    private let evidenceText = SQLite.Expression<String>("text")
    private let evidenceType = SQLite.Expression<String>("type")
    private let evidenceCreatedAt = SQLite.Expression<Date>("created_at")

    // Connection columns
    private let connId = SQLite.Expression<String>("id")
    private let connFromId = SQLite.Expression<String>("from_belief_id")
    private let connToId = SQLite.Expression<String>("to_belief_id")
    private let connStrength = SQLite.Expression<Double>("strength")

    @Published var allBeliefs: [Belief] = []

    private init() {
        setupDatabase()
        loadBeliefs()
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
        try db?.run(beliefs.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(text)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db?.run(evidence.create(ifNotExists: true) { t in
            t.column(evidenceId, primaryKey: true)
            t.column(evidenceBeliefId)
            t.column(evidenceText)
            t.column(evidenceType)
            t.column(evidenceCreatedAt)
        })

        try db?.run(connections.create(ifNotExists: true) { t in
            t.column(connId, primaryKey: true)
            t.column(connFromId)
            t.column(connToId)
            t.column(connStrength)
        })
    }

    // MARK: - Belief CRUD

    func loadBeliefs() {
        guard let db = db else { return }
        do {
            var loaded: [Belief] = []
            for row in try db.prepare(beliefs) {
                let beliefId = UUID(uuidString: row[id])!
                let beliefEvidence = loadEvidence(for: beliefId)
                let belief = Belief(
                    id: beliefId,
                    text: row[text],
                    createdAt: row[createdAt],
                    updatedAt: row[updatedAt],
                    evidenceItems: beliefEvidence
                )
                loaded.append(belief)
            }
            DispatchQueue.main.async {
                self.allBeliefs = loaded.sorted { $0.updatedAt > $1.updatedAt }
            }
        } catch {
            print("Load beliefs error: \(error)")
        }
    }

    func addBelief(_ belief: Belief) {
        guard let db = db else { return }
        do {
            try db.run(beliefs.insert(
                id <- belief.id.uuidString,
                text <- belief.text,
                createdAt <- belief.createdAt,
                updatedAt <- belief.updatedAt
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
                updatedAt <- Date()
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
            // Delete associated evidence
            let evidenceTarget = evidence.filter(evidenceBeliefId == belief.id.uuidString)
            try db.run(evidenceTarget.delete())
            // Delete associated connections
            let connFrom = connections.filter(connFromId == belief.id.uuidString)
            let connTo = connections.filter(connToId == belief.id.uuidString)
            try db.run(connFrom.delete())
            try db.run(connTo.delete())
            // Delete belief
            try db.run(target.delete())
            loadBeliefs()
        } catch {
            print("Delete belief error: \(error)")
        }
    }

    // MARK: - Evidence CRUD

    private func loadEvidence(for beliefId: UUID) -> [Evidence] {
        guard let db = db else { return [] }
        var items: [Evidence] = []
        do {
            let query = evidence.filter(evidenceBeliefId == beliefId.uuidString)
            for row in try db.prepare(query) {
                let ev = Evidence(
                    id: UUID(uuidString: row[evidenceId])!,
                    beliefId: UUID(uuidString: row[evidenceBeliefId])!,
                    text: row[evidenceText],
                    type: EvidenceType(rawValue: row[evidenceType]) ?? .support,
                    createdAt: row[evidenceCreatedAt]
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
                evidenceCreatedAt <- item.createdAt
            ))
            // Update belief updatedAt
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
}
