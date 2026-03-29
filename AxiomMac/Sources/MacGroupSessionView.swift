import SwiftUI

/// R22: Group belief work sessions for real-time collaborative belief examination
struct MacGroupSessionView: View {
    @State private var session: GroupBeliefSession?
    @State private var sessions: [GroupBeliefSession] = []
    @State private var showingNewSession = false
    @State private var evidenceText = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            if let session = session {
                activeSessionView(session: session)
            } else {
                sessionBrowserView
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showingNewSession) {
            NewSessionSheet { newSession in
                sessions.append(newSession)
                session = newSession
            }
        }
        .onAppear { loadSessions() }
    }

    // MARK: - Active Session View

    private func activeSessionView(session: GroupBeliefSession) -> some View {
        VStack(spacing: 0) {
            // Session header
            sessionHeader(session: session)

            Divider()
                .background(Theme.border)

            // Main content
            VStack(spacing: Theme.spacingL) {
                // Participant avatars
                participantsBar(session: session)

                // Current belief
                beliefCard(session: session)

                // Evidence feed
                evidenceFeed(session: session)

                // Evidence input
                evidenceInput(session: session)
            }
            .padding(Theme.screenMargin)
        }
    }

    // MARK: - Session Header

    private func sessionHeader(session: GroupBeliefSession) -> some View {
        HStack {
            Button {
                self.session = nil
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(session.status == .active ? Theme.accentGreen : Theme.textSecondary)
                        .frame(width: 6, height: 6)

                    Text(session.status == .active ? "Live" : "Ended")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            Button {
                // End session
                var updatedSession = session
                updatedSession.status = .ended
                if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                    sessions[index] = updatedSession
                }
                self.session = nil
            } label: {
                Text("End")
                    .font(.subheadline)
                    .foregroundColor(Theme.accentRed)
            }
        }
        .padding(Theme.screenMargin)
        .background(Theme.surface)
    }

    // MARK: - Participants Bar

    private func participantsBar(session: GroupBeliefSession) -> some View {
        HStack(spacing: Theme.spacingM) {
            ForEach(session.participants) { participant in
                VStack(spacing: Theme.spacingXS) {
                    ZStack {
                        Circle()
                            .fill(participant.isSpeaking ? Theme.accentGold.opacity(0.3) : Theme.surfaceElevated)
                            .frame(width: 48, height: 48)

                        Text(String(participant.name.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(participant.isSpeaking ? Theme.accentGold : Theme.textSecondary)

                        if participant.isSpeaking {
                            // Speaking indicator
                            Circle()
                                .stroke(Theme.accentGreen, lineWidth: 2)
                                .frame(width: 52, height: 52)
                        }
                    }

                    Text(participant.name)
                        .font(.caption)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Add participant button
            Button {
                // Add participant flow
            } label: {
                Circle()
                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 2, dash: [4]))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)
                    )
            }
        }
    }

    // MARK: - Belief Card

    private func beliefCard(session: GroupBeliefSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Label("Current Belief", systemImage: "brain.head.profile")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accentBlue)

                Spacer()

                Text("\(session.participants.count) examining")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Text(session.currentBelief.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Belief score indicator
            HStack(spacing: Theme.spacingS) {
                ScoreIndicator(
                    label: "Supporting",
                    count: session.currentBelief.supportingCount,
                    color: Theme.accentGreen
                )

                ScoreIndicator(
                    label: "Contradicting",
                    count: session.currentBelief.contradictingCount,
                    color: Theme.accentRed
                )

                Spacer()

                Text("Score: \(Int(session.currentBelief.score))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.scoreColor(for: session.currentBelief.score))
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .stroke(Theme.accentGold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Evidence Feed

    private func evidenceFeed(session: GroupBeliefSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("Evidence")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text("\(session.evidence.count) pieces")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            if session.evidence.isEmpty {
                emptyEvidenceState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingS) {
                        ForEach(session.evidence) { evidence in
                            EvidenceCard(
                                evidence: evidence,
                                from: evidence.authorName
                            )
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var emptyEvidenceState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "lightbulb")
                .font(.system(size: 32))
                .foregroundColor(Theme.textSecondary.opacity(0.3))

            Text("No evidence yet")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            Text("Be the first to add evidence for or against this belief")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
        .background(Theme.surfaceElevated)
        .cornerRadius(Theme.cornerRadiusM)
    }

    // MARK: - Evidence Input

    private func evidenceInput(session: GroupBeliefSession) -> some View {
        HStack(spacing: Theme.spacingM) {
            // Type selector
            Picker("Type", selection: .constant(EvidenceType.support)) {
                Label("Support", systemImage: "checkmark.circle.fill")
                    .tag(EvidenceType.support)
                Label("Contradict", systemImage: "xmark.circle.fill")
                    .tag(EvidenceType.contradict)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            // Text field
            TextField("Add your evidence...", text: $evidenceText)
                .textFieldStyle(.plain)
                .padding(Theme.spacingM)
                .background(Theme.surfaceElevated)
                .cornerRadius(Theme.cornerRadiusM)

            // Submit button
            Button {
                submitEvidence()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(evidenceText.isEmpty ? Theme.textSecondary : Theme.accentGold)
            }
            .disabled(evidenceText.isEmpty)
        }
    }

    // MARK: - Session Browser

    private var sessionBrowserView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Group Sessions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)

                    Text("Work together to examine beliefs")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Button {
                    showingNewSession = true
                } label: {
                    Label("New Session", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentGold)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            Divider()
                .background(Theme.border)

            // Sessions list
            if sessions.isEmpty {
                emptySessionsState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(sessions) { sess in
                            SessionListCard(session: sess) {
                                session = sess
                            }
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    private var emptySessionsState: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))

            VStack(spacing: Theme.spacingS) {
                Text("No Group Sessions")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)

                Text("Start a group session to examine beliefs together with friends")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                showingNewSession = true
            } label: {
                Label("Create Session", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentGold)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func loadSessions() {
        // Load from storage
        if let data = UserDefaults.standard.data(forKey: "groupSessionsV2"),
           let decoded = try? JSONDecoder().decode([GroupBeliefSession].self, from: data) {
            sessions = decoded
        }
    }

    private func submitEvidence() {
        guard !evidenceText.isEmpty, var currentSession = session else { return }

        let newEvidence = GroupEvidence(
            id: UUID(),
            text: evidenceText,
            type: .support,
            authorName: "You",
            createdAt: Date()
        )

        currentSession.evidence.append(newEvidence)
        session = currentSession

        if let index = sessions.firstIndex(where: { $0.id == currentSession.id }) {
            sessions[index] = currentSession
        }

        evidenceText = ""
        saveSessions()
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "groupSessionsV2")
        }
    }
}

// MARK: - Score Indicator

struct ScoreIndicator: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Evidence Card

struct EvidenceCard: View {
    let evidence: GroupEvidence
    let from: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Image(systemName: evidence.type.icon)
                .font(.subheadline)
                .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(evidence.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)

                HStack {
                    Text(from)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.accentBlue)

                    Text("·")
                        .foregroundColor(Theme.textSecondary)

                    Text(evidence.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Session List Card

struct SessionListCard: View {
    let session: GroupBeliefSession
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text(session.currentBelief.text)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(session.status == .active ? Theme.accentGreen : Theme.textSecondary)
                        .frame(width: 8, height: 8)

                    Text(session.status == .active ? "Live" : "Ended")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            HStack {
                // Participants
                HStack(spacing: -8) {
                    ForEach(session.participants.prefix(4)) { participant in
                        Circle()
                            .fill(Theme.accentBlue.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(participant.name.prefix(1)).uppercased())
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.accentBlue)
                            )
                    }

                    if session.participants.count > 4 {
                        Circle()
                            .fill(Theme.surfaceElevated)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("+\(session.participants.count - 4)")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textSecondary)
                            )
                    }
                }

                Text("\(session.participants.count) participants")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                // Evidence count
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accentGold)
                    Text("\(session.evidence.count) evidence")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Button("Join", action: onJoin)
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentGold)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
    let onCreate: (GroupBeliefSession) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var beliefText = ""
    @State private var participantNames = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    TextField("Session Title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)

                    TextField("Belief to examine (what are you working on together?)", text: $beliefText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusM)
                        .lineLimit(2...4)

                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Participants (comma-separated names)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)

                        TextField("Alice, Bob, Charlie", text: $participantNames)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusM)
                    }

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("New Group Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let participants = participantNames
                            .split                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                            .map { name in
                                GroupParticipant(id: UUID(), name: name, isSpeaking: false)
                            }

                        let belief = Belief(text: beliefText)
                        let newSession = GroupBeliefSession(
                            id: UUID(),
                            title: title,
                            participants: participants,
                            currentBelief: belief,
                            evidence: [],
                            status: .active
                        )
                        onCreate(newSession)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || beliefText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Group Session Model

struct GroupBeliefSession: Identifiable, Codable {
    let id: UUID
    var title: String
    var participants: [GroupParticipant]
    var currentBelief: Belief
    var evidence: [GroupEvidence]
    var status: SessionStatus

    enum SessionStatus: String, Codable {
        case active
        case ended
    }
}

struct GroupParticipant: Identifiable, Codable {
    let id: UUID
    var name: String
    var isSpeaking: Bool
}

struct GroupEvidence: Identifiable, Codable {
    let id: UUID
    var text: String
    var type: EvidenceType
    var authorName: String
    var createdAt: Date
}

#Preview {
    MacGroupSessionView()
}
