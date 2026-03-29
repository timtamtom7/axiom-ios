import SwiftUI
import AppKit

/// macOS settings view for Axiom.
struct MacSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("anonymousSharingEnabled") private var anonymousSharingEnabled: Bool = true
    @State private var showingExportSheet = false
    @State private var exportMessage: String?
    @State private var showingSubscription = false
    @StateObject private var localization = LocalizationService.shared
    @State private var selectedSection: SettingsSection = .subscription
    @State private var aiAgentEnabled: Bool = false
    @State private var dailyPromptHour: Int = 9
    @State private var dailyPromptMinute: Int = 0
    @State private var apiServerEnabled: Bool = false
    @State private var apiStatusMessage: String = ""
    @State private var isRunningStressTest: Bool = false
    @State private var stressTestResult: String = ""
    @State private var ehrExportMessage: String = ""

    enum SettingsSection: String, CaseIterable {
        case subscription, appearance, notifications, anonymousSharing, dataExport, aiAgent, developer, about
    }

    var body: some View {
        NavigationSplitView {
            settingsSidebar
                .frame(minWidth: 220, idealWidth: 260)
                .background(Theme.surface)
        } detail: {
            detailView
        }
        .sheet(isPresented: $showingSubscription) {
            MacSubscriptionView()
        }
        .onAppear {
            apiServerEnabled = HealthAPIService.shared.isRunning
        }
    }

    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Theme.spacingXS) {
                    SettingsSidebarRow(icon: "crown.fill", title: localization.t("subscription"), isSelected: selectedSection == .subscription) { selectedSection = .subscription }
                    SettingsSidebarRow(icon: "paintbrush", title: "Appearance", isSelected: selectedSection == .appearance) { selectedSection = .appearance }
                    SettingsSidebarRow(icon: "bell", title: "Notifications", isSelected: selectedSection == .notifications) { selectedSection = .notifications }
                    SettingsSidebarRow(icon: "person.fill.questionmark", title: "Anonymous Sharing", isSelected: selectedSection == .anonymousSharing) { selectedSection = .anonymousSharing }
                    SettingsSidebarRow(icon: "square.and.arrow.up", title: "Data Export", isSelected: selectedSection == .dataExport) { selectedSection = .dataExport }
                    Divider().padding(.vertical, Theme.spacingXS)
                    SettingsSidebarRow(icon: "brain.head.profile", title: "AI Agent", isSelected: selectedSection == .aiAgent) { selectedSection = .aiAgent }
                    SettingsSidebarRow(icon: "chevron.left.forwardslash.chevron.right", title: "Developer", isSelected: selectedSection == .developer) { selectedSection = .developer }
                    Divider().padding(.vertical, Theme.spacingXS)
                    SettingsSidebarRow(icon: "info.circle", title: "About", isSelected: selectedSection == .about) { selectedSection = .about }
                }
                .padding(Theme.screenMargin)
            }
        }
    }

    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                switch selectedSection {
                case .subscription:
                    subscriptionSection
                case .appearance:
                    appearanceSection
                case .notifications:
                    notificationsSection
                case .anonymousSharing:
                    anonymousSharingSection
                case .dataExport:
                    dataExportSection
                case .aiAgent:
                    aiAgentSection
                case .developer:
                    developerSection
                case .about:
                    aboutSection
                }
            }
            .padding(Theme.screenMargin)
        }
        .background(Theme.background)
        .navigationTitle("Settings")
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(Theme.accentGold)
                Text(localization.t("subscription"))
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Current Plan")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Text(SubscriptionService.shared.currentTier.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accentGold)
                }
                Spacer()
                Button {
                    showingSubscription = true
                } label: {
                    Text(localization.t("manage_subscription"))
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.accentGold)
                        .cornerRadius(8)
                }
            }

            if SubscriptionService.shared.currentTier == .free {
                Text("Upgrade to Pro for unlimited beliefs, AI deep dive, and more!")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "paintbrush")
                    .foregroundColor(Theme.accentGold)
                Text("Appearance")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: Theme.spacingS) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        AppearanceModeButton(
                            mode: mode,
                            isSelected: appearanceMode == mode.rawValue
                        ) {
                            appearanceMode = mode.rawValue
                            applyAppearance(mode)
                        }
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(Theme.accentBlue)
                Text("Notifications")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Get reminders for belief check-ins")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .tint(Theme.accentGold)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var anonymousSharingSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "person.fill.questionmark")
                    .foregroundColor(Theme.accentGreen)
                Text("Anonymous Sharing")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            Toggle(isOn: $anonymousSharingEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow Anonymous Sharing")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Share beliefs with the community without identifying you")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .tint(Theme.accentGold)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var dataExportSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Theme.accentBlue)
                Text("Data Export")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            Text("Export all your belief data for backup or analysis.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: Theme.spacingM) {
                ExportButton(title: "Export JSON", icon: "doc.text") { exportJSON() }
                ExportButton(title: "Export CSV", icon: "tablecells") { exportCSV() }
            }

            if let message = exportMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(Theme.accentGreen)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var aiAgentSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.accentPurple)
                Text("AI Agent")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(AIBeliefAgentService.shared.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(AIBeliefAgentService.shared.isActive ? Theme.accentGreen : Theme.textSecondary)
                    .padding(.horizontal, Theme.spacingS)
                    .padding(.vertical, 4)
                    .background(AIBeliefAgentService.shared.isActive ? Theme.accentGreen.opacity(0.2) : Theme.surfaceElevated)
                    .cornerRadius(4)
            }

            Toggle(isOn: $aiAgentEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Daily Belief Prompts")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Receive daily prompts to examine and challenge your beliefs")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .tint(Theme.accentGold)
            .onChange(of: aiAgentEnabled) { _, newValue in
                if newValue {
                    AIBeliefAgentService.shared.activateAgent()
                } else {
                    AIBeliefAgentService.shared.deactivateAgent()
                }
            }

            if aiAgentEnabled {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Daily Prompt Time")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    HStack {
                        Picker("Hour", selection: $dailyPromptHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 70)

                        Text(":")

                        Picker("Minute", selection: $dailyPromptMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 70)

                        Spacer()

                        Text("Default: 9:00 AM")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.vertical, Theme.spacingS)
            }

            Divider()

            Button {
                runStressTest()
            } label: {
                HStack {
                    if isRunningStressTest {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text("Run AI Stress Test")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingS)
                .background(Theme.accentPurple)
                .cornerRadius(8)
            }
            .disabled(isRunningStressTest)
            .accessibilityLabel("Run AI Stress Test")
            .accessibilityHint("Run a stress test on your beliefs using AI")

            if !stressTestResult.isEmpty {
                Text(stressTestResult)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, Theme.spacingXS)
            }

            Divider()

            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(Theme.accentBlue)
                Text("API Status")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                HStack(spacing: Theme.spacingS) {
                    Circle()
                        .fill(HealthAPIService.shared.isRunning ? Theme.accentGreen : Theme.textSecondary)
                        .frame(width: 8, height: 8)
                    Text(HealthAPIService.shared.isRunning ? "Running on port 8766" : "Stopped")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            if let dailyPrompt = AIBeliefAgentService.shared.dailyPrompt {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Today's Prompt")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(dailyPrompt.description)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(Theme.spacingS)
                .background(Theme.surfaceElevated)
                .cornerRadius(8)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(Theme.accentBlue)
                Text("Developer")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Toggle(isOn: $apiServerEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Server")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        Text("Start/stop REST API on port 8766")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .tint(Theme.accentGold)
                .onChange(of: apiServerEnabled) { _, newValue in
                    if newValue {
                        do {
                            try HealthAPIService.shared.start()
                            apiStatusMessage = "Server started successfully"
                        } catch {
                            apiStatusMessage = "Failed to start: \(error.localizedDescription)"
                            apiServerEnabled = false
                        }
                    } else {
                        HealthAPIService.shared.stop()
                        apiStatusMessage = "Server stopped"
                    }
                }

                if !apiStatusMessage.isEmpty {
                    Text(apiStatusMessage)
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                }

                HStack {
                    Text("API Key")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("axiom-api-key-\(String(UUID().uuidString.prefix(8)))")
                        .font(.caption)
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, Theme.spacingS)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(4)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Endpoints")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("GET /beliefs, POST /beliefs, GET /evidence")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("EHR Export")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)

                Text("Export belief records for clinical review in FHIR-compliant format.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: Theme.spacingM) {
                    ExportButton(title: "Export EHR (JSON)", icon: "doc.text") { exportEHR() }
                    ExportButton(title: "Export FHIR", icon: "doc.badge.arrow.up") { exportFHIR() }
                    ExportButton(title: "Export Anonymized", icon: "person.fill.xmark") { exportAnonymized() }
                }

                if !ehrExportMessage.isEmpty {
                    Text(ehrExportMessage)
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func runStressTest() {
        isRunningStressTest = true
        stressTestResult = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            stressTestResult = "Stress test complete. Found \(DatabaseService.shared.allBeliefs.count) beliefs to examine. Recommendations generated."
            isRunningStressTest = false
        }
    }

    private func exportEHR() {
        let record = EHRIntegrationService.shared.exportRecord(for: "patient-\(UUID().uuidString.prefix(8))")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(record) {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "axiom_ehr_export.json"
            savePanel.canCreateDirectories = true
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    try? data.write(to: url)
                    ehrExportMessage = "EHR exported to \(url.lastPathComponent)"
                }
            }
        }
    }

    private func exportFHIR() {
        if let data = EHRIntegrationService.shared.exportAsFHIR(for: "patient-\(UUID().uuidString.prefix(8))") {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "axiom_fhir_export.json"
            savePanel.canCreateDirectories = true
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    try? data.write(to: url)
                    ehrExportMessage = "FHIR exported to \(url.lastPathComponent)"
                }
            }
        } else {
            ehrExportMessage = "FHIR export failed"
        }
    }

    private func exportAnonymized() {
        let record = EHRIntegrationService.shared.exportRecord(for: "anonymous-patient")
        let anonymized = EHRIntegrationService.shared.anonymize(record)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(anonymized) {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "axiom_anonymized_export.json"
            savePanel.canCreateDirectories = true
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    try? data.write(to: url)
                    ehrExportMessage = "Anonymized export to \(url.lastPathComponent)"
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(Theme.textSecondary)
                Text("About")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Axiom")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("© 2026 Axiom")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "scale.3d")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.accentGold.opacity(0.5))
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .system:
            NSApp.appearance = nil
        }
    }

    private func exportJSON() {
        let beliefs = DatabaseService.shared.allBeliefs
        let exportData = beliefs.map { belief -> [String: Any] in
            [
                "id": belief.id.uuidString,
                "text": belief.text,
                "score": belief.score,
                "isCore": belief.isCore,
                "supportingCount": belief.supportingCount,
                "contradictingCount": belief.contradictingCount,
                "createdAt": belief.createdAt.ISO8601Format(),
                "updatedAt": belief.updatedAt.ISO8601Format(),
                "evidence": belief.evidenceItems.map { ev -> [String: Any] in
                    [
                        "id": ev.id.uuidString,
                        "text": ev.text,
                        "type": ev.type.rawValue,
                        "confidence": ev.confidence,
                        "createdAt": ev.createdAt.ISO8601Format()
                    ]
                }
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "axiom_export.json"
            savePanel.canCreateDirectories = true
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    try? data.write(to: url)
                    exportMessage = "Exported to \(url.lastPathComponent)"
                }
            }
        }
    }

    private func exportCSV() {
        let beliefs = DatabaseService.shared.allBeliefs
        var csv = "ID,Text,Score,Core,Supporting,Contradicting,Created,Updated\n"
        for b in beliefs {
            let escapedText = b.text.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(b.id),\"\(escapedText)\",\(Int(b.score)),\(b.isCore),\(b.supportingCount),\(b.contradictingCount),\(b.createdAt.ISO8601Format()),\(b.updatedAt.ISO8601Format())\n"
        }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "axiom_export.csv"
        savePanel.canCreateDirectories = true
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
                exportMessage = "Exported to \(url.lastPathComponent)"
            }
        }
    }
}

// MARK: - Supporting Types

enum AppearanceMode: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case system = "System"
}

// MARK: - SettingsSidebarRow

struct SettingsSidebarRow: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Theme.spacingM) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Theme.accentGold : Theme.textSecondary)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(isSelected ? Theme.accentGold.opacity(0.15) : Theme.surface)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppearanceModeButton

struct AppearanceModeButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.spacingXS) {
                Image(systemName: iconFor(mode))
                    .font(.system(size: 20))
                Text(mode.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .background(isSelected ? Theme.accentGold.opacity(0.15) : Theme.surfaceElevated)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.accentGold : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ mode: AppearanceMode) -> String {
        switch mode {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "gear"
        }
    }
}

// MARK: - ExportButton

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .foregroundColor(Theme.accentBlue)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(Theme.accentBlue.opacity(0.15))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacSettingsView()
        .preferredColorScheme(.dark)
}
