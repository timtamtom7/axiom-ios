import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.5))

            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)

                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingXL)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(Theme.background)
                        .padding(.horizontal, Theme.spacingXL)
                        .padding(.vertical, Theme.spacingM)
                        .background(Theme.accentGold)
                        .cornerRadius(12)
                }
            }
        }
        .padding(Theme.screenMargin)
    }
}

#Preview {
    EmptyStateView(
        icon: "brain",
        title: "No Beliefs Yet",
        subtitle: "Start by recording a belief you hold about yourself.",
        actionTitle: "Add First Belief"
    ) {
        print("Action")
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
