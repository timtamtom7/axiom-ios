import SwiftUI

struct SettingsView: View {
    @StateObject private var dataService = DataService.shared
    @State private var notificationsEnabled = true
    @State private var weeklyDigest = true
    @State private var biometricLock = false
    @State private var darkMode = false
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirm = false
    @State private var selectedSubscription = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Subscription card
                SubscriptionCard()

                // Notifications
                SettingsSection(title: "Notifications") {
                    SettingsToggle(icon: "bell.fill", color: Theme.gold, title: "Daily Check-in Reminder", subtitle: "Reminds you to reflect on your beliefs", isOn: $notificationsEnabled)
                    SettingsToggle(icon: "calendar.badge.clock", color: Theme.accentBlue, title: "Weekly Digest", subtitle: "Summary of your belief progress", isOn: $weeklyDigest)
                }

                // Security
                SettingsSection(title: "Security") {
                    SettingsToggle(icon: "faceid", color: Theme.navy, title: "Biometric Lock", subtitle: "Require Face ID to open app", isOn: $biometricLock)
                }

                // Data
                SettingsSection(title: "Data & Privacy") {
                    SettingsRow(icon: "square.and.arrow.up", color: Theme.accentGreen, title: "Export My Data", subtitle: "Download all beliefs and evidence") {
                        showingExportSheet = true
                    }
                    SettingsRow(icon: "trash", color: Theme.accentRed, title: "Delete All Data", subtitle: "Permanently remove all your data") {
                        showingDeleteConfirm = true
                    }
                }

                // Appearance
                SettingsSection(title: "Appearance") {
                    SettingsToggle(icon: "moon.fill", color: Theme.accentBlue, title: "Dark Mode", subtitle: "Follow system appearance", isOn: $darkMode)
                }

                // About
                SettingsSection(title: "About") {
                    SettingsInfoRow(title: "Version", value: "1.0.0 (Build 1)")
                    SettingsInfoRow(title: "Made with", value: "SwiftUI + CBT principles")
                }

                Text("Axiom helps you examine and stress-test your beliefs using evidence-based cognitive behavioral techniques.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.surface)
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(isPresented: $showingExportSheet)
        }
        .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                dataService.beliefs.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your beliefs, evidence, and insights. This action cannot be undone.")
        }
    }
}

struct SubscriptionCard: View {
    @State private var selectedPlan = 1

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("Axiom Pro")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Text("Active")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.accentGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accentGreen.opacity(0.15))
                    .cornerRadius(4)
            }

            Text("Unlimited beliefs, AI stress tests, community access, and weekly synthesis reports.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineSpacing(2)

            HStack(spacing: 10) {
                ForEach([("Free", 0), ("Monthly", 1), ("Annual", 2)], id: \.1) { plan in
                    Button {
                        selectedPlan = plan.1
                    } label: {
                        VStack(spacing: 2) {
                            Text(plan.0)
                                .font(.system(size: 11, weight: .semibold))
                            if plan.1 == 1 {
                                Text("$4.99")
                                    .font(.system(size: 9))
                            } else if plan.1 == 2 {
                                Text("$39.99/yr")
                                    .font(.system(size: 9))
                            } else {
                                Text("$0")
                                    .font(.system(size: 9))
                            }
                        }
                        .foregroundColor(selectedPlan == plan.1 ? .white : Theme.navy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPlan == plan.1 ? Theme.navy : Theme.surface)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.gold.opacity(0.4), lineWidth: 1)
        )
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 0) {
                content
            }
            .background(Theme.cardBg)
            .cornerRadius(12)
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.navy)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.gold)
        }
        .padding(14)
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.navy)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Theme.navy)
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
    }
}

struct ExportSheet: View {
    @Binding var isPresented: Bool
    @State private var exportFormat = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Export Data")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Button("Done") { isPresented = false }
                    .foregroundColor(Theme.gold)
            }

            Text("Choose format:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $exportFormat) {
                Text("JSON").tag(0)
                Text("CSV").tag(1)
                Text("PDF Report").tag(2)
            }
            .pickerStyle(.segmented)

            Button {
                isPresented = false
            } label: {
                Text("Export")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.navy)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Theme.cream)
        .frame(width: 340)
    }
}
