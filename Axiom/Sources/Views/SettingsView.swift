import SwiftUI

/// R13-R20: Comprehensive settings view
struct SettingsView: View {
    @StateObject private var subscription = SubscriptionService.shared
    @StateObject private var localization = LocalizationService.shared
    @StateObject private var agent = AIBeliefAgentService.shared
    @StateObject private var retention = RetentionService.shared

    @State private var showingLanguageSettings = false
    @State private var showingSubscriptionSettings = false
    @State private var showingAgentSettings = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        // Account Section
                        accountSection

                        // Subscription Section
                        subscriptionSection

                        // AI Agent Section (R16)
                        agentSection

                        // Localization Section (R13)
                        localizationSection

                        // Retention Section (R13)
                        retentionSection

                        // About Section
                        aboutSection
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingLanguageSettings) {
                LanguageSettingsView()
            }
            .sheet(isPresented: $showingSubscriptionSettings) {
                SubscriptionView()
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Account")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                SettingsRow(
                    icon: "person.circle",
                    iconColor: Theme.accentBlue,
                    title: "Profile",
                    subtitle: "Manage your account"
                )

                Divider().background(Theme.border)

                SettingsRow(
                    icon: "icloud",
                    iconColor: Theme.accentBlue,
                    title: "Sync",
                    subtitle: "iCloud backup enabled"
                )
            }
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Subscription")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                // Current plan
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accentGold)

                    VStack(alignment: .leading) {
                        Text("Current Plan")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Text(subscription.currentTier.displayName)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                    }

                    Spacer()

                    Button {
                        showingSubscriptionSettings = true
                    } label: {
                        Text("Manage")
                            .font(.subheadline)
                            .foregroundColor(Theme.accentGold)
                    }
                }
                .padding(Theme.spacingM)

                if subscription.isTeams {
                    Divider().background(Theme.border)

                    HStack {
                        Image(systemName: "person.3")
                            .foregroundColor(Theme.accentBlue)
                        Text("Teams Members")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(subscription.teamsMemberCount)")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingM)
                }

                Divider().background(Theme.border)

                // Features
                ForEach(subscription.currentTier.features.prefix(3), id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.accentGreen)
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingXS)
                }
            }
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }

    private var agentSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("AI Belief Agent")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { agent.isActive },
                    set: { newValue in
                        if newValue {
                            agent.activateAgent()
                        } else {
                            agent.deactivateAgent()
                        }
                    }
                ))
                .labelsHidden()
                .tint(Theme.accentGold)
            }

            Text("R16: Proactive belief work with daily prompts, evidence gathering, and cognitive restructuring coaching")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            if agent.isActive {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Theme.accentGold)
                        Text("Daily Prompt")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        if let prompt = agent.dailyPrompt {
                            Text(prompt.priority.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(prompt.priority == .high ? Theme.accentRed : Theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(4)
                        }
                    }
                    .padding(Theme.spacingM)

                    if let prompt = agent.dailyPrompt {
                        Divider().background(Theme.border)

                        Text(prompt.suggestedAction)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                            .padding(Theme.spacingM)
                    }
                }
                .background(Theme.surface)
                .cornerRadius(12)
            }
        }
    }

    private var localizationSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Language & Region")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                Button {
                    showingLanguageSettings = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(Theme.accentBlue)
                        Text("Language")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(localization.currentLanguage.flag)
                        Text(localization.currentLanguage.displayName)
                            .foregroundColor(Theme.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingM)
                }

                Divider().background(Theme.border)

                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(Theme.accentBlue)
                    Text("Measurement System")
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("Metric")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }

    private var retentionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Your Progress")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.accentGold)
                    Text("Days Since Install")
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(retention.daysSinceInstall)")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)

                Divider().background(Theme.border)

                HStack {
                    Image(systemName: "checkmark.seal")
                        .foregroundColor(Theme.accentGreen)
                    Text("Retention Milestone")
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(retention.currentRetentionMilestone.rawValue)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)

                Divider().background(Theme.border)

                // Progress indicators
                HStack(spacing: Theme.spacingL) {
                    MilestoneIndicator(
                        day: 1,
                        completed: retention.day1Completed,
                        isActive: retention.currentRetentionMilestone == .day1
                    )
                    MilestoneIndicator(
                        day: 7,
                        completed: retention.day7Completed,
                        isActive: retention.currentRetentionMilestone == .day7
                    )
                    MilestoneIndicator(
                        day: 30,
                        completed: retention.day30Completed,
                        isActive: retention.currentRetentionMilestone == .day30
                    )
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("About")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)

                Divider().background(Theme.border)

                HStack {
                    Text("Build")
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("20")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.surface)
            .cornerRadius(12)

            // Axiom 3.0 Vision (R20)
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Label("Axiom 3.0 Vision", systemImage: "telescope")
                    .font(.caption)
                    .foregroundColor(Theme.accentGold)
                Text("\"Change your beliefs, change your life.\"")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            }
            .padding(Theme.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
    }
}

struct MilestoneIndicator: View {
    let day: Int
    let completed: Bool
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(isActive ? Theme.accentGold : Theme.textSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)

                if completed {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                } else {
                    Text("\(day)")
                        .font(.caption)
                        .foregroundColor(isActive ? Theme.accentGold : Theme.textSecondary)
                }
            }

            Text("Day \(day)")
                .font(.caption2)
                .foregroundColor(isActive ? Theme.accentGold : Theme.textSecondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
