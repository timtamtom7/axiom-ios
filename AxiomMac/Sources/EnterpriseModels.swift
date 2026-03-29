import Foundation
import SwiftUI

struct AuditLogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let actorName: String
    let action: AuditAction
    let details: AuditDetails?
}

enum AuditAction: String {
    case login = "login"
    case logout = "logout"
    case dataAccess = "data_access"
    case dataExport = "data_export"
    case settingsChange = "settings_change"
}

struct AuditDetails {
    let description: String
}

@MainActor
class AuditLogService: ObservableObject {
    static let shared = AuditLogService()
    
    @Published private(set) var entries: [AuditLogEntry] = []
    
    func getEntries() -> [AuditLogEntry] {
        return entries
    }
    
    func log(action: AuditAction, actorName: String, details: AuditDetails? = nil) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            actorName: actorName,
            action: action,
            details: details
        )
        entries.append(entry)
    }
}

struct TeamManagementView: View {
    var body: some View {
        VStack {
            Text("Team Management")
                .font(.headline)
            Text("Configure teams and members")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct DataExportView: View {
    var body: some View {
        VStack {
            Text("Data Export")
                .font(.headline)
            Text("Export user data for compliance")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
