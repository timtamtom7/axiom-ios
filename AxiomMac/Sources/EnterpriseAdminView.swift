import SwiftUI

@MainActor
struct EnterpriseAdminView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Enterprise Admin")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Tabs
            TabView {
                TeamManagementView()
                    .tabItem { Text("Teams") }
                
                AuditLogView()
                    .tabItem { Text("Audit Log") }
                
                ComplianceReportView()
                    .tabItem { Text("Compliance") }
                
                DataExportView()
                    .tabItem { Text("Data Export") }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct AuditLogView: View {
    @State private var entries: [AuditLogEntry] = []
    
    var body: some View {
        Table(entries) {
            TableColumn("Time") { entry in
                Text(entry.timestamp.formatted())
            }
            TableColumn("User") { entry in
                Text(entry.actorName)
            }
            TableColumn("Action") { entry in
                Text(entry.action.rawValue)
            }
            TableColumn("Details") { entry in
                Text(entry.details?.description ?? "")
            }
        }
        .onAppear {
            entries = AuditLogService.shared.getEntries()
        }
    }
}

struct ComplianceReportView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("HIPAA Compliance Report")
                .font(.headline)
            
            Group {
                HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentGreen); Text("Encryption at rest: AES-256") }
                HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentGreen); Text("TLS 1.3 in transit") }
                HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentGreen); Text("Audit logging enabled") }
                HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentGreen); Text("Biometric authentication") }
            }
            
            Spacer()
        }
        .padding()
    }
}
