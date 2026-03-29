import SwiftUI

/// Shimmer skeleton loading effect for content placeholders
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.15),
                Color.gray.opacity(0.35),
                Color.gray.opacity(0.15)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 200 : -200)
        .animation(
            .linear(duration: 1.5).repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear { isAnimating = true }
    }
}

/// Skeleton card placeholder for belief rows
struct SkeletonBeliefCard: View {
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Circle()
                .fill(Theme.surfaceElevated)
                .frame(width: 40, height: 40)
                .overlay(SkeletonView())
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 180, height: 14)
                    .overlay(SkeletonView())
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 120, height: 10)
                    .overlay(SkeletonView())
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

/// Skeleton row placeholder for evidence items
struct SkeletonEvidenceRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.surfaceElevated)
                .frame(height: 14)
                .overlay(SkeletonView())
                .clipShape(RoundedRectangle(cornerRadius: 4))

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.surfaceElevated)
                .frame(width: 240, height: 14)
                .overlay(SkeletonView())
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 60, height: 10)
                    .overlay(SkeletonView())
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 80, height: 10)
                    .overlay(SkeletonView())
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(Theme.spacingS)
        .background(Theme.surfaceElevated)
        .cornerRadius(8)
    }
}

/// Skeleton loading view for community feed
struct SkeletonCommunityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surfaceElevated)
                    .frame(width: 50, height: 12)
                    .overlay(SkeletonView())
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Circle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 32, height: 32)
                    .overlay(SkeletonView())
                    .clipShape(Circle())
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.surfaceElevated)
                .frame(height: 16)
                .overlay(SkeletonView())
                .clipShape(RoundedRectangle(cornerRadius: 4))

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.surfaceElevated)
                .frame(width: 200, height: 16)
                .overlay(SkeletonView())
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceElevated)
                        .frame(width: 60, height: 10)
                        .overlay(SkeletonView())
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}
