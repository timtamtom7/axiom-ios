import SwiftUI

/// R7: Therapist connection and management view
/// Integrates therapist features from AxiomIOSMac into the iOS app
struct TherapistConnectionView: View {
    @StateObject private var therapistService = TherapistIntegrationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var therapistCode = ""
    @State private var errorMessage: String?
    @State private var showingReportSheet = false
    @State private var generatedReport: String?
    @State private var isGeneratingReport = false
    @State private var selectedBelief: Belief?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if subscriptionService.canAccessTherapistConnection {
                    connectedView
                } else {
                    upgradeRequiredView
                }
            }
            .navigationTitle("Therapist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                if let report = generatedReport {
                    ProgressReportSheet(report: report) {
                        showingReportSheet = false
                    }
                }
            }
            .sheet(item: $selectedBelief) { belief in
                TherapistShareBeliefSheet(belief: belief, onDismiss: {
                    selectedBelief = nil
                })
            }
        }
    }

    // MARK: - Connected View

    private var connectedView: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Therapist Card
                if let therapist = therapistService.connectedTherapist {
                    therapistCard(therapist)
                }

                // Share Belief Section
                shareBeliefSection

                // Session History
                sessionHistorySection

                // Disconnect
                disconnectButton
            }
            .padding(Theme.screenMargin)
        }
    }

    private func therapistCard(_ therapist: TherapistProfile) -> some View {
        VStack(spacing: Theme.spacingM) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.accentBlue.opacity(0.2))
                    .frame(width: 80, height: 80)
                Text(therapist.name.prefix(1))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Theme.accentBlue)
            }

            Text(therapist.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text(therapist.specialization)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: Theme.spacingS) {
                if therapist.isVerified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(Theme.accentGreen)
                }
                Text("License: \(therapist.licenseNumber)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Button {
                shareBeliefSection
            } label: {
                Label("Share Belief", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentBlue)
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private var shareBeliefSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Share with Therapist")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Select a belief to share with \(therapistService.connectedTherapist?.name ?? "your therapist")")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            ForEach(DatabaseService.shared.allBeliefs.prefix(5)) { belief in
                Button {
                    selectedBelief = belief
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(belief.text)
                                .font(.subheadline)
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            Text("Score: \(Int(belief.score))%")
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingS)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(Theme.cornerRadiusM)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("Session History")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button {
                    generateReport()
                } label: {
                    if isGeneratingReport {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Get Report", systemImage: "doc.text")
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .disabled(isGeneratingReport)
            }

            if therapistService.sessionHistory.isEmpty {
                Text("No sessions yet. Share a belief to start.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, Theme.spacingS)
            } else {
                ForEach(therapistService.sessionHistory.prefix(5)) { session in
                    HStack {
                        Image(systemName: sessionIcon(for: session.type))
                            .foregroundColor(Theme.accentBlue)
                        VStack(alignment: .leading) {
                            Text(session.type.displayName)
                                .font(.caption)
                                .foregroundColor(Theme.textPrimary)
                            Text(session.date.formatted(.relative(presentation: .named)))
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Theme.spacingXS)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
    }

    private var disconnectButton: some View {
        Button(role: .destructive) {
            therapistService.disconnect()
            dismiss()
        } label: {
            Text("Disconnect Therapist")
                .font(.subheadline)
                .foregroundColor(Theme.accentRed)
        }
        .padding(.top, Theme.spacingM)
    }

    // MARK: - Upgrade Required View

    private var upgradeRequiredView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "heart.text.square")
                .font(.system(size: 72))
                .foregroundColor(Theme.accentBlue.opacity(0.5))

            Text("Therapist Connection")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("Connect with a licensed therapist who can review your belief audits and provide professional guidance.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                featureRow(icon: "checkmark.circle.fill", text: "Share belief audits with your therapist")
                featureRow(icon: "checkmark.circle.fill", text: "Generate professional progress reports")
                featureRow(icon: "checkmark.circle.fill", text: "Collaborative treatment planning")
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusL)
            .padding(.horizontal, Theme.screenMargin)

            Text("Available with Axiom Therapy")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .foregroundColor(Theme.accentGreen)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Helpers

    private func sessionIcon(for type: SessionType) -> String {
        switch type {
        case .beliefShared: return "square.and.arrow.up"
        case .reportGenerated: return "doc.text"
        case .checkIn: return "message"
        case .treatmentPlanUpdated: return "list.clipboard"
        }
    }

    private func generateReport() {
        isGeneratingReport = true
        Task {
            do {
                let report = try await therapistService.requestProgressReport()
                generatedReport = report
                showingReportSheet = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isGeneratingReport = false
        }
    }
}

// MARK: - Share Belief Sheet

struct TherapistShareBeliefSheet: View {
    let belief: Belief
    let onDismiss: () -> Void

    @StateObject private var therapistService = TherapistIntegrationService.shared
    @State private var isSharing = false
    @State private var shared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    if shared {
                        successView
                    } else {
                        shareContent
                    }
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Share Belief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }

    private var shareContent: some View {
        VStack(spacing: Theme.spacingL) {
            // Belief Preview
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Belief")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text(belief.text)
                    .font(.body)
                    .foregroundColor(Theme.textPrimary)

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("\(Int(belief.score))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.scoreColor(for: belief.score))
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Evidence")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("\(belief.supportingCount) support, \(belief.contradictingCount) contradict")
                            .font(.caption)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusL)

            Text("This belief will be shared with your connected therapist for professional review.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                share()
            } label: {
                if isSharing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Share with Therapist")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.spacingM)
            .background(Theme.accentBlue)
            .foregroundColor(.white)
            .cornerRadius(Theme.cornerRadiusL)
            .disabled(isSharing)
        }
    }

    private var successView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Theme.accentGreen)

            Text("Belief Shared!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("Your therapist can now review this belief during your next session.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(Theme.cornerRadiusL)
            }
        }
    }

    private func share() {
        isSharing = true
        Task {
            do {
                try await therapistService.shareBeliefWithTherapist(belief)
                shared = true
            } catch {
                // Handle error
            }
            isSharing = false
        }
    }
}

// MARK: - Progress Report Sheet

struct ProgressReportSheet: View {
    let report: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    Text(report)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.screenMargin)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: report) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - SessionType Extension

extension SessionType {
    var displayName: String {
        switch self {
        case .beliefShared: return "Belief shared"
        case .reportGenerated: return "Report generated"
        case .checkIn: return "Check-in"
        case .treatmentPlanUpdated: return "Treatment plan updated"
        }
    }
}

#Preview {
    TherapistConnectionView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
