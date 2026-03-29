import SwiftUI

/// Premium error state view with retry capability
struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    var title: String = "Something went wrong"
    var icon: String = "exclamationmark.triangle.fill"

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(Theme.accentRed.opacity(0.8))

            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingM)
            }

            if let retryAction = retryAction {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    retryAction()
                } label: {
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingXL)
                    .padding(.vertical, Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(Theme.spacingXL)
    }
}

/// Subtle inline error banner for smaller contexts
struct ErrorBanner: View {
    let message: String
    let dismissAction: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(Theme.accentRed)

            Text(message)
                .font(.caption)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if let dismissAction = dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.accentRed.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: Theme.spacingXL) {
        ErrorView(message: "Failed to load beliefs. Check your connection and try again.") {
            print("Retry")
        }

        Divider()

        ErrorBanner(message: "Could not save evidence. Please try again.", dismissAction: {
            print("Dismiss")
        })
        .padding(.horizontal)
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
