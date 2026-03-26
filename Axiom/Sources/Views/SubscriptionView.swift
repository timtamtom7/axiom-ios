import SwiftUI

/// Paywall / upgrade view for Pro tier
struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isUpgrading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingXL) {
                        // Header
                        headerSection

                        // Current status
                        currentStatusSection

                        // Pro features
                        proFeaturesSection

                        // Upgrade button
                        upgradeButton

                        // Restore purchases
                        restoreButton
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Axiom Pro")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Theme.accentGold)

            Text("Unlock Your Full Mind")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Upgrade to Pro and gain unlimited access to every belief audit feature.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Current Plan: \(subscriptionService.currentTier.displayName)")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if !subscriptionService.isPro {
                HStack {
                    Text("\(subscriptionService.beliefsRemaining) beliefs remaining")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    if !subscriptionService.canAddBelief {
                        Text("Limit reached")
                            .font(.caption)
                            .foregroundColor(Theme.accentRed)
                    }
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Theme.accentGold)
                    Text("Unlimited beliefs active")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)
            }
        }
    }

    private var proFeaturesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Pro Features")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ForEach(SubscriptionTier.pro.features, id: \.self) { feature in
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accentGreen)
                        .font(.body)
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var upgradeButton: some View {
        Button {
            upgradeToPro()
        } label: {
            if isUpgrading {
                ProgressView()
                    .tint(.black)
            } else {
                VStack(spacing: 4) {
                    Text("Upgrade to Pro")
                        .font(.headline)
                    Text("$4.99/month")
                        .font(.caption)
                        .fontWeight(.regular)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingM)
        .background(Theme.accentGold)
        .foregroundColor(.black)
        .cornerRadius(12)
        .disabled(isUpgrading)
    }

    private var restoreButton: some View {
        Button {
            // In real app, this would restore purchases
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(Theme.accentBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingM)
    }

    private func upgradeToPro() {
        isUpgrading = true
        // Simulate StoreKit purchase flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            subscriptionService.simulatePurchase(tier: .pro)
            isUpgrading = false
        }
    }
}

/// Inline upgrade prompt shown when free user tries to add more than 3 beliefs
struct UpgradePromptBanner: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    let onUpgrade: () -> Void

    var body: some View {
        if !subscriptionService.canAddBelief {
            HStack(spacing: Theme.spacingM) {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.accentGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Free plan limit reached")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.textPrimary)
                    Text("Upgrade to Pro for unlimited beliefs")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.accentGold)
                        .cornerRadius(8)
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }
}
