import SwiftUI

/// R7: Accountability Partners view
/// Allows users to connect with accountability partners for mutual belief audit support
struct AccountabilityPartnersView: View {
    @StateObject private var partnersStore = AccountabilityPartnersStore.shared
    @State private var showingInvitePartner = false
    @State private var showingFindPartner = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if partnersStore.partners.isEmpty {
                    emptyState
                } else {
                    partnersList
                }
            }
            .navigationTitle("Partners")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFindPartner = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingInvitePartner) {
                InvitePartnerSheet()
            }
            .sheet(isPresented: $showingFindPartner) {
                FindPartnerSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "person.2")
                .font(.system(size: 72))
                .foregroundColor(Theme.textSecondary.opacity(0.3))

            Text("Find an Accountability Partner")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("Connect with someone who understands.\nShare goals, check in daily, grow together.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            Button {
                showingFindPartner = true
            } label: {
                Text("Find a Partner")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentBlue)

            Spacer()
        }
    }

    private var partnersList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                // Active partners
                ForEach(partnersStore.partners) { partner in
                    PartnerCard(partner: partner)
                }

                // Invite section
                Button {
                    showingInvitePartner = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(Theme.accentBlue)
                        Text("Invite Another Partner")
                            .foregroundColor(Theme.accentBlue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadiusL)
                }
            }
            .padding(Theme.screenMargin)
        }
    }
}

// MARK: - Partner Card

struct PartnerCard: View {
    let partner: AccountabilityPartnerData
    @StateObject private var partnersStore = AccountabilityPartnersStore.shared
    @State private var showingCheckIn = false

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            // Header
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Text(partner.partnerName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(avatarColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.partnerName)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: Theme.spacingS) {
                        // Streak
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(partner.checkInStreak > 0 ? Theme.accentGold : Theme.textSecondary)
                                .font(.caption)
                            Text("\(partner.checkInStreak) day streak")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Text("•")
                            .foregroundColor(Theme.textSecondary)

                        // Last check-in
                        if let lastCheckIn = partner.lastCheckIn {
                            Text("Last: \(lastCheckIn.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }

                Spacer()

                // Status
                Circle()
                    .fill(partner.isActive ? Theme.accentGreen : Theme.textSecondary)
                    .frame(width: 10, height: 10)
            }

            // Goals
            if !partner.goals.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Shared Goals")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    ForEach(partner.goals.prefix(3), id: \.self) { goal in
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: goalStatusIcon(for: goal) ? "checkmark.circle.fill" : "circle")
                                .font(.caption2)
                                .foregroundColor(goalStatusIcon(for: goal) ? Theme.accentGreen : Theme.textSecondary)
                            Text(goal)
                                .font(.caption)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingS)
            }

            // Check-in button
            Button {
                showingCheckIn = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Check In Together")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingS)
                .background(Theme.accentBlue.opacity(0.1))
                .foregroundColor(Theme.accentBlue)
                .cornerRadius(Theme.cornerRadiusM)
            }

            // Partner since
            Text("Paired \(partner.pairedAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(partner.partnerName). \(partner.checkInStreak) day check-in streak. \(partner.goals.count) shared goals.")
        .sheet(isPresented: $showingCheckIn) {
            PartnerCheckInSheet(partner: partner)
        }
    }

    private var avatarColor: Color {
        let colors: [Color] = [Theme.accentBlue, Theme.accentGreen, Theme.accentGold, Theme.accentPurple]
        let index = abs(partner.partnerName.hashValue) % colors.count
        return colors[index]
    }

    private func goalStatusIcon(for goal: String) -> Bool {
        // Simplified: completed goals marked in partner data
        false
    }
}

// MARK: - Check-In Sheet

struct PartnerCheckInSheet: View {
    let partner: AccountabilityPartnerData
    @Environment(\.dismiss) private var dismiss
    @StateObject private var partnersStore = AccountabilityPartnersStore.shared

    @State private var didCompleteGoal = false
    @State private var reflectionText = ""
    @State private var sharedProgress: SharedProgress?
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        // Header
                        VStack(spacing: Theme.spacingS) {
                            Text("Daily Check-In")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)

                            Text("with \(partner.partnerName)")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }

                        // Goals review
                        if !partner.goals.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.spacingM) {
                                Text("Review Your Goals")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)

                                ForEach(partner.goals, id: \.self) { goal in
                                    HStack {
                                        Image(systemName: didCompleteGoal ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(didCompleteGoal ? Theme.accentGreen : Theme.textSecondary)
                                        Text(goal)
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusL)
                        }

                        // Reflection
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("How's your belief audit going?")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            TextEditor(text: $reflectionText)
                                .frame(minHeight: 100)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                                .foregroundColor(Theme.textPrimary)

                            Text("Share with \(partner.partnerName)")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(Theme.screenMargin)
                }

                // Bottom CTA
                VStack {
                    Spacer()
                    Button {
                        sendCheckIn()
                    } label: {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Check-In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(reflectionText.isEmpty ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(reflectionText.isEmpty ? Theme.textSecondary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .disabled(reflectionText.isEmpty || isSending)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func sendCheckIn() {
        isSending = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            partnersStore.recordCheckIn(for: partner)
            dismiss()
        }
    }
}

// MARK: - Invite Partner Sheet

struct InvitePartnerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var name = ""
    @State private var personalMessage = ""
    @State private var isSending = false
    @State private var sent = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if sent {
                    sentView
                } else {
                    inviteForm
                }
            }
            .navigationTitle("Invite Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var inviteForm: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Info
                VStack(spacing: Theme.spacingS) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.accentBlue)

                    Text("Invite someone you trust")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text("Your accountability partner will receive an email with instructions to join Axiom.")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Form
                VStack(spacing: Theme.spacingM) {
                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Partner's Name")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("Jane Smith", text: $name)
                            .textFieldStyle(.plain)
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)
                    }

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Partner's Email")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("jane@example.com", text: $email)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)
                    }

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Personal Message (optional)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextEditor(text: $personalMessage)
                            .frame(minHeight: 80)
                            .padding(Theme.spacingS)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)
                            .foregroundColor(Theme.textPrimary)
                    }
                }

                Spacer()
            }
            .padding(Theme.screenMargin)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                sendInvite()
            } label: {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Send Invitation")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.spacingM)
            .background(name.isEmpty || email.isEmpty ? Theme.surfaceElevated : Theme.accentBlue)
            .foregroundColor(name.isEmpty || email.isEmpty ? Theme.textSecondary : .white)
            .cornerRadius(Theme.cornerRadiusL)
            .disabled(name.isEmpty || email.isEmpty || isSending)
            .padding(Theme.screenMargin)
        }
    }

    private var sentView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Theme.accentGreen)

            Text("Invitation Sent!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("We'll let you know when \(name) joins Axiom.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(Theme.cornerRadiusL)
            }
            .padding(Theme.screenMargin)
        }
    }

    private func sendInvite() {
        isSending = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            sent = true
            isSending = false
        }
    }
}

// MARK: - Find Partner Sheet

struct FindPartnerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textSecondary)
                        TextField("Search by name or email...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadiusM)
                    .padding(.horizontal, Theme.screenMargin)

                    if searchText.isEmpty {
                        // Suggested partners
                        VStack(alignment: .leading, spacing: Theme.spacingM) {
                            Text("Suggested Partners")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, Theme.screenMargin)

                            Text("Connect with people you already trust — a friend, therapist, or family member who understands your journey.")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, Theme.screenMargin)
                        }
                        .padding(.top, Theme.spacingL)
                    } else {
                        // Results
                        ScrollView {
                            VStack(spacing: Theme.spacingM) {
                                ForEach(0..<3, id: \.self) { _ in
                                    HStack {
                                        Circle()
                                            .fill(Theme.accentBlue.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text("?")
                                                    .foregroundColor(Theme.accentBlue)
                                            )
                                        VStack(alignment: .leading) {
                                            Text("Search result")
                                                .font(.subheadline)
                                                .foregroundColor(Theme.textPrimary)
                                            Text("email@example.com")
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Button("Invite") {}
                                            .font(.caption)
                                            .buttonStyle(.bordered)
                                    }
                                    .padding(Theme.spacingM)
                                    .background(Theme.surface)
                                    .cornerRadius(Theme.cornerRadiusL)
                                }
                            }
                            .padding(.horizontal, Theme.screenMargin)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Find Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AccountabilityPartnersView()
        .preferredColorScheme(.dark)
}
