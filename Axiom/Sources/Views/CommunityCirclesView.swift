import SwiftUI

/// R12: Community Circles view — browse circles, see shared belief challenges
struct CommunityCirclesView: View {
    @StateObject private var service = CommunityCircleService.shared
    @State private var selectedCircle: CommunityCircle?
    @State private var showingCreateCircle = false
    @State private var showingJoinCircle = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented picker
                    pickerView

                    // Search bar
                    searchBar

                    // Content
                    if filteredCircles.isEmpty {
                        emptyState
                    } else {
                        circlesList
                    }
                }
            }
            .navigationTitle("Community Circles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingCreateCircle = true
                        } label: {
                            Label("Create Circle", systemImage: "plus.circle")
                        }

                        Button {
                            showingJoinCircle = true
                        } label: {
                            Label("Join Circle", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCircle) {
                CreateCommunityCircleSheet()
            }
            .sheet(isPresented: $showingJoinCircle) {
                JoinCircleSheet()
            }
            .sheet(item: $selectedCircle) { circle in
                CircleDetailView(circle: circle)
            }
        }
    }

    // MARK: - Subviews

    private var pickerView: some View {
        Picker("View", selection: $searchText) {
            Text("Discover").tag("")
            Text("Joined").tag("joined")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.screenMargin)
        .padding(.vertical, Theme.spacingS)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)
            TextField("Search circles...", text: $searchText)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .padding(.horizontal, Theme.screenMargin)
        .padding(.bottom, Theme.spacingS)
    }

    private var circlesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                // Joined circles section
                if searchText == "joined" {
                    let joined = service.getJoinedCircles()
                    if joined.isEmpty {
                        noJoinedState
                    } else {
                        ForEach(joined) { circle in
                            CommunityCircleCard(circle: circle)
                                .onTapGesture {
                                    selectedCircle = circle
                                }
                        }
                    }
                } else {
                    // All circles
                    ForEach(filteredCircles) { circle in
                        CommunityCircleCard(circle: circle)
                            .onTapGesture {
                                selectedCircle = circle
                            }
                    }
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.bottom, Theme.spacingL)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "person.3.fill",
                title: "No Circles Found",
                subtitle: searchText == "joined"
                    ? "Join a circle to connect with others."
                    : "Create or join a circle to get started.",
                actionTitle: "Create Circle"
            ) {
                showingCreateCircle = true
            }
            Spacer()
        }
    }

    private var noJoinedState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary)
            Text("No Joined Circles")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Join a circle using an invite code to see it here.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                showingJoinCircle = true
            } label: {
                Text("Join Circle")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentBlue)
        }
        .padding(Theme.screenMargin)
    }

    private var filteredCircles: [CommunityCircle] {
        let allCircles = service.getCircles()
        if searchText == "joined" {
            return allCircles.filter { $0.isJoined }
        }
        if searchText.isEmpty {
            return allCircles
        }
        return allCircles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Circle Card

struct CommunityCircleCard: View {
    let circle: CommunityCircle
    @State private var isJoining = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header
            HStack {
                CircleAvatar(circle: circle, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(circle.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    HStack(spacing: Theme.spacingS) {
                        Label("\(circle.memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        if circle.sharedChallenges.isEmpty == false {
                            Text("•")
                                .foregroundColor(Theme.textSecondary)
                            Label("\(circle.sharedChallenges.count) challenges", systemImage: "flame")
                                .font(.caption)
                                .foregroundColor(Color.orange)
                        }
                    }
                }

                Spacer()

                if circle.isJoined {
                    Text("Joined")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingXS)
                        .background(Theme.accentGreen.opacity(0.2))
                        .foregroundColor(Theme.accentGreen)
                        .cornerRadius(Theme.cornerRadiusPill)
                }
            }

            // Description
            Text(circle.description)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)

            // Shared challenges preview
            if let latestChallenge = circle.sharedChallenges.first {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Latest Challenge")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    HStack {
                        SupportBadge(level: latestChallenge.supportLevel)
                        Text(latestChallenge.beliefText)
                            .font(.caption)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(Theme.spacingS)
                .background(Theme.surfaceElevated)
                .cornerRadius(Theme.cornerRadiusM)
            }

            // Members preview
            if circle.members.isEmpty == false {
                HStack(spacing: -8) {
                    ForEach(circle.members.prefix(4)) { member in
                        MemberAvatar(member: member, size: 28)
                    }
                    if circle.memberCount > 4 {
                        Text("+\(circle.memberCount - 4)")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.leading, Theme.spacingS)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusL)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                .stroke(circleAccentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var circleAccentColor: Color {
        switch circle.circleColor {
        case "blue": return Theme.accentBlue
        case "green": return Theme.accentGreen
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "pink": return Color.pink
        case "teal": return Color.cyan
        default: return Theme.accentBlue
        }
    }
}

// MARK: - Circle Avatar

struct CircleAvatar: View {
    let circle: CommunityCircle
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(circleAccentColor.opacity(0.2))
                .frame(width: size, height: size)

            Image(systemName: "person.3.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(circleAccentColor)
        }
    }

    private var circleAccentColor: Color {
        switch circle.circleColor {
        case "blue": return Theme.accentBlue
        case "green": return Theme.accentGreen
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "pink": return Color.pink
        case "teal": return Color.cyan
        default: return Theme.accentBlue
        }
    }
}

// MARK: - Member Avatar

struct MemberAvatar: View {
    let member: CircleMember
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(randomColor.opacity(0.2))
                .frame(width: size, height: size)

            Text(member.avatarInitials)
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundColor(randomColor)
        }
        .overlay(
            Circle()
                .stroke(Theme.surface, lineWidth: 2)
        )
    }

    private var randomColor: Color {
        let colors: [Color] = [Theme.accentBlue, Theme.accentGreen, .purple, Color.orange, .pink, .cyan]
        let index = abs(member.name.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Support Badge

struct SupportBadge: View {
    let level: SharedBeliefChallenge.SupportLevel

    var body: some View {
        Text(level.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Theme.spacingXS)
            .padding(.vertical, 2)
            .background(level.color.opacity(0.2))
            .foregroundColor(level.color)
            .cornerRadius(Theme.cornerRadiusS)
    }
}

// MARK: - Circle Detail View

struct CircleDetailView: View {
    let circle: CommunityCircle
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CommunityCircleService.shared
    @State private var showingAddChallenge = false
    @State private var selectedChallenge: SharedBeliefChallenge?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        // Header
                        headerSection

                        // Invite code
                        if circle.isJoined {
                            inviteCodeSection
                        }

                        // Members
                        membersSection

                        // Shared Challenges
                        challengesSection

                        Spacer()
                    }
                    .padding(.horizontal, Theme.screenMargin)
                    .padding(.bottom, 100)
                }

                // Bottom CTA
                bottomCTA
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddChallenge) {
                AddChallengeSheet(circleId: circle.id)
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailSheet(challenge: challenge, circleId: circle.id)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                CircleAvatar(circle: circle, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)
                    Text("\(circle.memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }

            Text(circle.description)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Invite Code")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            HStack {
                Text(circle.inviteCode)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accentBlue)
                Spacer()
                Button {
                    UIPasteboard.general.string = circle.inviteCode
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.accentBlue.opacity(0.1))
            .cornerRadius(Theme.cornerRadiusM)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Members")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ForEach(circle.members) { member in
                HStack {
                    MemberAvatar(member: member, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.textPrimary)
                        Text("\(member.beliefsShared) beliefs • \(member.challengesCompleted) resolved")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(Theme.spacingS)
                .background(Theme.surface)
                .cornerRadius(Theme.cornerRadiusM)
            }
        }
    }

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text("Shared Challenges")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                if circle.isJoined {
                    Button {
                        showingAddChallenge = true
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                    }
                }
            }

            if circle.sharedChallenges.isEmpty {
                Text("No challenges yet. Be the first to share a belief!")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .padding(Theme.spacingM)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadiusM)
            } else {
                ForEach(circle.sharedChallenges) { challenge in
                    BeliefChallengeCard(challenge: challenge)
                        .onTapGesture {
                            selectedChallenge = challenge
                        }
                }
            }
        }
    }

    private var bottomCTA: some View {
        VStack {
            Spacer()
            if circle.isJoined {
                Button {
                    Task {
                        try? await service.leaveCircle(circle)
                        dismiss()
                    }
                } label: {
                    Text("Leave Circle")
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingM)
                .background(Theme.surfaceElevated)
                .foregroundColor(.red)
                .cornerRadius(Theme.cornerRadiusL)
                .padding(Theme.screenMargin)
            } else {
                Button {
                    Task {
                        _ = try? await service.joinCircle(code: circle.inviteCode)
                    }
                } label: {
                    Text("Join Circle")
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingM)
                .background(Theme.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(Theme.cornerRadiusL)
                .padding(Theme.screenMargin)
            }
        }
    }
}

// MARK: - Challenge Card

struct BeliefChallengeCard: View {
    let challenge: SharedBeliefChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                SupportBadge(level: challenge.supportLevel)
                Spacer()
                if challenge.isResolved {
                    Label("Resolved", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accentGreen)
                }
            }

            Text(challenge.beliefText)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)

            HStack {
                Text("by \(challenge.authorName)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Label("\(challenge.evidenceCount)", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Label("\(challenge.comments.count)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Create Circle Sheet

struct CreateCommunityCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CommunityCircleService.shared
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Circle Name")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("e.g. Daily Belief Check-in", text: $name)
                                .textFieldStyle(.plain)
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                        }

                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextEditor(text: $description)
                                .frame(minHeight: 80)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                                .foregroundColor(Theme.textPrimary)
                        }

                        Spacer()
                    }
                    .padding(Theme.screenMargin)
                }

                VStack {
                    Spacer()
                    Button {
                        createCircle()
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Circle")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(name.isEmpty ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(name.isEmpty ? Theme.textSecondary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .disabled(name.isEmpty || isCreating)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createCircle() {
        isCreating = true
        Task {
            _ = try? await service.createCircle(name: name, description: description)
            dismiss()
        }
    }
}

// MARK: - Join Circle Sheet

struct JoinCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CommunityCircleService.shared
    @State private var code = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Invite Code")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("e.g. DAILY01", text: $code)
                            .textFieldStyle(.plain)
                            .font(.system(.title3, design: .monospaced))
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)
                            .onChange(of: code) { _, newValue in
                                code = String(newValue.uppercased().prefix(6))
                            }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(Theme.screenMargin)

                VStack {
                    Spacer()
                    Button {
                        joinCircle()
                    } label: {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Join Circle")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(code.count < 4 ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(code.count < 4 ? Theme.textSecondary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .disabled(code.count < 4 || isJoining)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func joinCircle() {
        isJoining = true
        errorMessage = nil
        Task {
            do {
                _ = try await service.joinCircle(code: code)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isJoining = false
            }
        }
    }
}

// MARK: - Add Challenge Sheet

struct AddChallengeSheet: View {
    let circleId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CommunityCircleService.shared
    @State private var beliefText = ""
    @State private var supportLevel: SharedBeliefChallenge.SupportLevel = .undecided
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Your Belief")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextEditor(text: $beliefText)
                                .frame(minHeight: 100)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                                .foregroundColor(Theme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Support Level")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Picker("Support Level", selection: $supportLevel) {
                                ForEach(SharedBeliefChallenge.SupportLevel.allCases, id: \.self) { level in
                                    Text(level.label).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Spacer()
                    }
                    .padding(Theme.screenMargin)
                }

                VStack {
                    Spacer()
                    Button {
                        submitChallenge()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Share Belief")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(beliefText.isEmpty ? Theme.surfaceElevated : Theme.accentBlue)
                    .foregroundColor(beliefText.isEmpty ? Theme.textSecondary : .white)
                    .cornerRadius(Theme.cornerRadiusL)
                    .disabled(beliefText.isEmpty || isSubmitting)
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Share Belief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitChallenge() {
        isSubmitting = true
        Task {
            try? await service.addChallenge(to: circleId, beliefText: beliefText, supportLevel: supportLevel)
            dismiss()
        }
    }
}

// MARK: - Challenge Detail Sheet

struct ChallengeDetailSheet: View {
    let challenge: SharedBeliefChallenge
    let circleId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CommunityCircleService.shared
    @State private var newComment = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        // Challenge header
                        VStack(alignment: .leading, spacing: Theme.spacingM) {
                            HStack {
                                SupportBadge(level: challenge.supportLevel)
                                Spacer()
                                if challenge.isResolved {
                                    Label("Resolved", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(Theme.accentGreen)
                                }
                            }

                            Text(challenge.beliefText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.textPrimary)

                            HStack {
                                Text("Shared by \(challenge.authorName)")
                                Spacer()
                                Text(challenge.createdAt.formatted(.relative(presentation: .named)))
                            }
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        }
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusL)

                        // Evidence
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Evidence (\(challenge.evidenceCount))")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Text("No evidence added yet.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }

                        // Comments
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Discussion (\(challenge.comments.count))")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            ForEach(challenge.comments) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(comment.authorName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        Text(comment.createdAt.formatted(.relative(presentation: .named)))
                                            .font(.caption2)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)
                            }
                        }

                        // Add comment
                        HStack {
                            TextField("Add a comment...", text: $newComment)
                                .textFieldStyle(.plain)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusM)

                            Button {
                                addComment()
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(newComment.isEmpty ? Theme.textSecondary : Theme.accentBlue)
                            }
                            .disabled(newComment.isEmpty)
                        }

                        Spacer()
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !challenge.isResolved {
                        Button("Resolve") {
                            resolveChallenge()
                        }
                    }
                }
            }
        }
    }

    private func addComment() {
        guard !newComment.isEmpty else { return }
        Task {
            try? await service.addComment(to: challenge.id, in: circleId, text: newComment)
            newComment = ""
        }
    }

    private func resolveChallenge() {
        Task {
            try? await service.resolveChallenge(challenge.id, in: circleId)
            dismiss()
        }
    }
}

// MARK: - SharedBeliefChallenge.SupportLevel Extension

extension SharedBeliefChallenge.SupportLevel: CaseIterable {
    static var allCases: [SharedBeliefChallenge.SupportLevel] {
        [.strong, .moderate, .weak, .undecided]
    }
}

#Preview {
    CommunityCirclesView()
        .preferredColorScheme(.dark)
}
