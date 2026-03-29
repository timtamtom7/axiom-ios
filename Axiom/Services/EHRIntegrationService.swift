import Foundation

/// R16: Electronic Health Record integration for clinical use
/// HIPAA-compliant data export for therapist/clinical review

struct DateRange: Codable, Equatable {
    let start: Date
    let end: Date

    init(from startDate: Date, to endDate: Date) {
        self.start = startDate
        self.end = endDate
    }
}

struct EHRRecord: Codable {
    let patientId: String
    let beliefs: [Belief]
    let evidence: [Evidence]
    let sessionCount: Int
    let dateRange: DateRange
    let exportedAt: Date
    let recordVersion: String

    init(patientId: String, beliefs: [Belief], sessionCount: Int, dateRangeStart: Date, dateRangeEnd: Date) {
        self.patientId = patientId
        self.beliefs = beliefs
        self.evidence = beliefs.flatMap { $0.evidenceItems }
        self.sessionCount = sessionCount
        self.dateRange = DateRange(from: dateRangeStart, to: dateRangeEnd)
        self.exportedAt = Date()
        self.recordVersion = "1.0"
    }
}

struct AnonymizedRecord: Codable {
    let recordId: String
    let beliefs: [AnonymizedBelief]
    let evidence: [AnonymizedEvidence]
    let sessionCount: Int
    let dateRange: DateRange
    let exportedAt: Date
    let anonymizationVersion: String

    struct AnonymizedBelief: Codable {
        let id: String
        let textHash: String
        let score: Double
        let isCore: Bool
        let category: String?
        let evidenceCount: Int
        let createdDaysAgo: Int
    }

    struct AnonymizedEvidence: Codable {
        let id: String
        let beliefHash: String
        let textHash: String
        let type: String
        let confidence: Double
        let createdDaysAgo: Int
    }
}

// FHIR Types
struct FHIRCoding: Codable {
    let system: String
    let code: String
    let display: String
}

struct FHIRCodeableConcept: Codable {
    let coding: [FHIRCoding]
}

struct FHIRReference: Codable {
    let reference: String
}

struct FHIRBundle: Codable {
    let resourceType: String
    let id: String
    let meta: FHIRBundleMeta
    let type: String
    let entry: [FHIRBundleEntry]

    struct FHIRBundleMeta: Codable {
        let versionId: String
        let lastUpdated: Date
    }

    struct FHIRBundleEntry: Codable {
        let fullUrl: String
        let resource: FHIRObservation
    }

    struct FHIRObservation: Codable {
        let resourceType: String
        let id: String
        let status: String
        let code: FHIRCodeableConcept
        let subject: FHIRReference
        let effectiveDateTime: Date
        let valueString: String
        let component: [FHIRKomponent]

        struct FHIRKomponent: Codable {
            let code: FHIRCodeableConcept
            let valueString: String
        }
    }
}

struct FHIRExport: Codable {
    let resourceType: String
    let id: String
    let meta: FHIRExportMeta
    let status: String
    let useContext: [FHIRUseContext]
    let subject: FHIRSubject
    let date: Date
    let institution: [FHIRInstitution]?

    struct FHIRExportMeta: Codable {
        let versionId: String
        let lastUpdated: Date
    }

    struct FHIRUseContext: Codable {
        let code: FHIRCodeableConcept
        let value: FHIRCodeableConcept
    }

    struct FHIRSubject: Codable {
        let reference: String
    }

    struct FHIRInstitution: Codable {
        let reference: String
    }
}

final class EHRIntegrationService: @unchecked Sendable {
    static let shared = EHRIntegrationService()

    private let anonymizationSalt = "axiom-ehr-salt-v1"

    /// Export belief work records for therapist/clinical review
    @MainActor
    func exportRecord(for patientId: String) -> EHRRecord {
        let beliefs = DatabaseService.shared.allBeliefs.filter { !$0.isArchived }

        let startDate = beliefs.map { $0.createdAt }.min() ?? Date()
        let endDate = beliefs.map { $0.updatedAt }.max() ?? Date()

        return EHRRecord(
            patientId: patientId,
            beliefs: beliefs,
            sessionCount: estimateSessionCount(from: beliefs),
            dateRangeStart: startDate,
            dateRangeEnd: endDate
        )
    }

    /// Export as FHIR-compliant JSON Bundle
    @MainActor
    func exportAsFHIR(for patientId: String) -> Data? {
        let record = exportRecord(for: patientId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let fhirBundle = FHIRBundle(
            resourceType: "Bundle",
            id: UUID().uuidString,
            meta: FHIRBundle.FHIRBundleMeta(versionId: "1", lastUpdated: Date()),
            type: "collection",
            entry: record.beliefs.enumerated().map { index, belief in
                FHIRBundle.FHIRBundleEntry(
                    fullUrl: "urn:uuid:\(belief.id)",
                    resource: FHIRBundle.FHIRObservation(
                        resourceType: "Observation",
                        id: belief.id.uuidString,
                        status: "final",
                        code: FHIRCodeableConcept(
                            coding: [FHIRCoding(
                                system: "http://axiom.health/belief",
                                code: "BELIEF",
                                display: belief.text
                            )]
                        ),
                        subject: FHIRReference(reference: "Patient/\(patientId)"),
                        effectiveDateTime: belief.createdAt,
                        valueString: "\(Int(belief.score))",
                        component: belief.evidenceItems.map { ev in
                            FHIRBundle.FHIRObservation.FHIRKomponent(
                                code: FHIRCodeableConcept(
                                    coding: [FHIRCoding(
                                        system: "http://axiom.health/evidence",
                                        code: ev.type.rawValue.uppercased(),
                                        display: ev.type.rawValue
                                    )]
                                ),
                                valueString: ev.text
                            )
                        }
                    )
                )
            }
        )

        return try? encoder.encode(fhirBundle)
    }

    /// Anonymize record for research/sharing
    func anonymize(_ record: EHRRecord) -> AnonymizedRecord {
        return AnonymizedRecord(
            recordId: generateAnonymousId(),
            beliefs: record.beliefs.map { belief in
                AnonymizedRecord.AnonymizedBelief(
                    id: UUID().uuidString,
                    textHash: hashText(belief.text),
                    score: belief.score,
                    isCore: belief.isCore,
                    category: belief.rootCause,
                    evidenceCount: belief.evidenceItems.count,
                    createdDaysAgo: daysAgo(from: belief.createdAt)
                )
            },
            evidence: record.evidence.map { ev in
                AnonymizedRecord.AnonymizedEvidence(
                    id: UUID().uuidString,
                    beliefHash: hashText(ev.beliefId.uuidString),
                    textHash: hashText(ev.text),
                    type: ev.type.rawValue,
                    confidence: ev.confidence,
                    createdDaysAgo: daysAgo(from: ev.createdAt)
                )
            },
            sessionCount: record.sessionCount,
            dateRange: record.dateRange,
            exportedAt: Date(),
            anonymizationVersion: "1.0"
        )
    }

    /// Generate FHIR-compliant export
    @MainActor
    func generateFHIRDocument(for patientId: String) -> FHIRExport? {
        let record = exportRecord(for: patientId)

        return FHIRExport(
            resourceType: "Document",
            id: UUID().uuidString,
            meta: FHIRExport.FHIRExportMeta(versionId: "1", lastUpdated: Date()),
            status: "current",
            useContext: [],
            subject: FHIRExport.FHIRSubject(reference: "Patient/\(patientId)"),
            date: Date(),
            institution: nil
        )
    }

    // MARK: - Private Helpers

    private func estimateSessionCount(from beliefs: [Belief]) -> Int {
        let uniqueDays = Set(beliefs.map { Calendar.current.startOfDay(for: $0.createdAt) })
        return max(uniqueDays.count, 1)
    }

    private func generateAnonymousId() -> String {
        return "AXM-\(UUID().uuidString.prefix(8).uppercased())"
    }

    private func hashText(_ text: String) -> String {
        let combined = "\(anonymizationSalt)-\(text)"
        var hasher = Hasher()
        hasher.combine(combined)
        return String(hasher.finalize())
    }

    private func daysAgo(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}
