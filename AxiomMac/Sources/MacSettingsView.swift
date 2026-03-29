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
    }

    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Theme.spacingXS) {
                    SettingsSidebarRow(icon: "crown.fill", title: localization.t("subscription"))
                    SettingsSidebarRow(icon: "paintbrush", title: "Appearance")
                    SettingsSidebarRow(icon: "bell", title: "Notifications")
                    SettingsSidebarRow(icon: "person.fill.questionmark", title: "Anonymous Sharing")
                    SettingsSidebarRow(icon: "square.and.arrow.up", title: "Data Export")
                    SettingsSidebarRow(icon: "info.circle", title: "About")
                }
                .padding(Theme.screenMargin)
            }
        }
    }

    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                subscriptionSection
                appearanceSection
                notificationsSection
                anonymousSharingSection
                dataExportSection
                aboutSection
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

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(8)
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
