import SwiftUI

/// R13: Subscription tier management view for macOS
struct MacSubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var localization = LocalizationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingXL) {
                        headerSection
                        tierComparisonTable
                        currentPlanSection
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle(localization.t("subscription"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.accentGold)

            Text("Unlock Your Full Potential")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("Choose the plan that fits your belief work journey")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Theme.spacingL)
    }

    private var tierComparisonTable: some View {
        VStack(spacing: Theme.spacingM) {
            // Header row
            HStack(spacing: Theme.spacingS) {
                Text("Feature")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                    Text(tier.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(tier == subscriptionService.currentTier ? Theme.accentGold : Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingXS)
                        .background(tier == subscriptionService.currentTier ? Theme.accentGold.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, Theme.spacingM)

            Divider()
                .background(Theme.border)

            // Feature rows
            featureRow(feature: "Max Beliefs", free: "3", pro: localization.t("unlimited"), therapy: localization.t("unlimited"), teams: localization.t("unlimited"))
            featureRow(feature: "AI Deep Dive", free: "—", pro: "✓", therapy: "✓", teams: "✓")
            featureRow(feature: "Belief Network", free: "—", pro: "✓", therapy: "✓", teams: "✓")
            featureRow(feature: "Evolution Tracking", free: "—", pro: "✓", therapy: "✓", teams: "✓")
            featureRow(feature: "Therapist Connection", free: "—", pro: "—", therapy: "✓", teams: "—")
            featureRow(feature: "Treatment Plans", free: "—", pro: "—", therapy: "✓", teams: "—")
            featureRow(feature: "Group Workshops", free: "—", pro: "—", therapy: "—", teams: "✓")
            featureRow(feature: "Shared Projects", free: "—", pro: "—", therapy: "—", teams: "✓")
        }
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func featureRow(feature: String, free: String, pro: String, therapy: String, teams: String) -> some View {
        HStack(spacing: Theme.spacingS) {
            Text(feature)
                .font(.caption)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach([free, pro, therapy, teams], id: \.self) { value in
                Text(value)
                    .font(.caption)
                    .foregroundColor(value == "✓" ? Theme.accentGreen : (value == "—" ? Theme.textSecondary : Theme.textPrimary))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
    }

    private var currentPlanSection: some View {
        VStack(spacing: Theme.spacingM) {
            HStack {
                Text("Current Plan:")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text(subscriptionService.currentTier.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accentGold)
                Spacer()
            }

            if subscriptionService.currentTier == .free {
                Button {
                    // Simulate upgrade to Pro for demo
                    subscriptionService.simulatePurchase(tier: .pro)
                } label: {
                    Label("Upgrade to Pro", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingM)
                        .background(Theme.accentGold)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            } else {
                VStack(spacing: Theme.spacingS) {
                    Text("Monthly cost: $\(String(format: "%.2f", subscriptionService.monthlyTeamsCost))")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    Button {
                        subscriptionService.downgradeToFree()
                    } label: {
                        Text("Downgrade to Free")
                            .font(.subheadline)
                            .foregroundColor(Theme.accentRed)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    MacSubscriptionView()
        .preferredColorScheme(.dark)
}
