import SwiftUI

struct BeliefDetailView: View {
    @StateObject private var viewModel: BeliefDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingArchiveSheet = false
    @State private var archiveReason = ""
    @State private var showingAIAnalysis = false
    @State private var aiAnalysis = ""
    @State private var aiAnalysisError: String?
    @State private var isLoadingAIAnalysis = false
    @State private var opposingViewpoint = ""
    @State private var isLoadingOpposing = false

    init(belief: Belief) {
        _viewModel = StateObject(wrappedValue: BeliefDetailViewModel(belief: belief))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    headerSection
                    scoreSection
                    actionButtonsSection

                    // Connections
                    if !viewModel.connectedBeliefs.isEmpty {
                        connectionsSection
                    }

                    // Checkpoints / Outcome tracking
                    if !viewModel.checkpoints.isEmpty {
                        checkpointsSection
                    }

                    // Supporting Evidence
                    evidenceSection(
                        title: "Supporting Evidence",
                        icon: "checkmark.circle.fill",
                        color: Theme.accentGreen,
                        items: viewModel.supportingEvidence
                    )

                    // Contradicting Evidence
                    evidenceSection(
                        title: "Contradicting Evidence",
                        icon: "xmark.circle.fill",
                        color: Theme.accentRed,
                        items: viewModel.contradictingEvidence
                    )

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, Theme.screenMargin)
            }
        }
        .navigationTitle("Belief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.toggleCore()
                    } label: {
                        Label(
                            viewModel.belief.isCore ? "Remove Core Label" : "Mark as Core",
                            systemImage: viewModel.belief.isCore ? "diamond" : "diamond.fill"
                        )
                    }

                    Button {
                        viewModel.showingConnections = true
                    } label: {
                        Label("Manage Connections", systemImage: "link")
                    }

                    Button {
                        viewModel.showingCheckIn = true
                    } label: {
                        Label("Schedule Check-in", systemImage: "clock.arrow.circlepath")
                    }

                    Button {
                        showingAIAnalysis = true
                        isLoadingAIAnalysis = true
                        aiAnalysisError = nil
                        Task {
                            do {
                                aiAnalysis = try await AIStressTestService().getAnalysis(for: viewModel.belief)
                            } catch {
                                aiAnalysisError = error.localizedDescription
                            }
                            isLoadingAIAnalysis = false
                        }
                    } label: {
                        Label("AI Analysis", systemImage: "wand.and.stars")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingArchiveSheet = true
                    } label: {
                        Label("Archive Belief", systemImage: "archivebox")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Belief", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showingAddEvidence) {
            AddEvidenceView(beliefId: viewModel.belief.id) { text, type, confidence, url, label in
                viewModel.addEvidence(text: text, type: type, confidence: confidence, sourceURL: url, sourceLabel: label)
            }
        }
        .sheet(isPresented: $viewModel.showingStressTest) {
            AIStressTestView(belief: viewModel.belief)
        }
        .sheet(isPresented: $viewModel.showingDeepDive) {
            AIDeepDiveView(belief: viewModel.belief)
        }
        .sheet(isPresented: $viewModel.showingConnections) {
            ConnectionsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingCheckIn) {
            CheckInSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingArchiveSheet) {
            ArchiveBeliefSheet(viewModel: viewModel, reason: $archiveReason)
        }
        .sheet(isPresented: $showingAIAnalysis) {
            AIAnalysisSheet(
                analysis: aiAnalysis,
                belief: viewModel.belief,
                isLoading: isLoadingAIAnalysis,
                error: aiAnalysisError
            )
        }
        .alert("Delete Belief?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteBelief()
                dismiss()
            }
        } message: {
            Text("This will permanently delete this belief and all its evidence.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                if viewModel.belief.isCore {
                    Text("CORE BELIEF")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accentGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accentGold.opacity(0.15))
                        .cornerRadius(4)
                }
                Spacer()
            }

            Text(viewModel.belief.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Theme.spacingM) {
                Text("Created \(viewModel.belief.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                if let root = viewModel.belief.rootCause {
                    Text("•")
                        .foregroundColor(Theme.textSecondary)
                    Text(root)
                        .font(.caption)
                        .foregroundColor(Theme.accentBlue)
                }

                if let checkIn = viewModel.belief.checkInScheduledAt {
                    Text("•")
                        .foregroundColor(Theme.textSecondary)
                    Label(checkIn.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(Theme.accentGold)
                }
            }
        }
        .padding(.top, Theme.spacingM)
    }

    private var scoreSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Evidence Score")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Text(scoreDescription)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                if !viewModel.checkpoints.isEmpty {
                    let initial = viewModel.checkpoints.last?.score ?? viewModel.belief.score
                    let delta = viewModel.belief.score - initial
                    if abs(delta) > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                            Text("\(Int(abs(delta))) pts since tracking")
                        }
                        .font(.caption2)
                        .foregroundColor(delta > 0 ? Theme.accentGreen : Theme.accentRed)
                    }
                }
            }

            Spacer()

            ScoreBadge(score: viewModel.belief.score)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var scoreDescription: String {
        let score = viewModel.belief.score
        if score < 40 {
            return "Evidence leans against this belief"
        } else if score < 70 {
            return "Evidence is mixed"
        } else {
            return "Evidence supports this belief"
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: Theme.spacingM) {
            HStack(spacing: Theme.spacingM) {
                Button {
                    viewModel.showingStressTest = true
                } label: {
                    Label("Stress Test", systemImage: "wand.and.stars")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingS)
                        .background(Theme.accentBlue.opacity(0.15))
                        .foregroundColor(Theme.accentBlue)
                        .cornerRadius(8)
                }

                Button {
                    viewModel.showingDeepDive = true
                } label: {
                    Label("AI Deep Dive", systemImage: "bubble.left.and.bubble.right")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingS)
                        .background(Theme.accentBlue.opacity(0.15))
                        .foregroundColor(Theme.accentBlue)
                        .cornerRadius(8)
                }
            }

            Button {
                Task {
                    isLoadingOpposing = true
                    do {
                        let result = try await AIStressTestService().suggestOpposingViewpoint(for: viewModel.belief)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            opposingViewpoint = result
                        }
                    } catch {
                        withAnimation {
                            opposingViewpoint = "Couldn't generate a viewpoint right now. Try again later."
                        }
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoadingOpposing = false
                    }
                }
            } label: {
                HStack {
                    if isLoadingOpposing {
                        ProgressView()
                            .tint(Theme.accentGold)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "lightbulb")
                    }
                    Text(isLoadingOpposing ? "Generating..." : "Get Opposing Viewpoint")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingS)
                .background(Theme.accentGold.opacity(0.1))
                .foregroundColor(Theme.accentGold)
                .cornerRadius(8)
            }
            .disabled(isLoadingOpposing)

            if !opposingViewpoint.isEmpty {
                Text(opposingViewpoint)
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .padding(Theme.spacingM)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(Theme.accentBlue)
                Text("Connected Beliefs")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("(\(viewModel.connectedBeliefs.count))")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }

            ForEach(viewModel.connectedBeliefs) { connected in
                NavigationLink(destination: BeliefDetailView(belief: connected)) {
                    HStack {
                        ScoreBadge(score: connected.score)
                        Text(connected.text)
                            .font(.callout)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(Theme.spacingS)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(8)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var checkpointsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(Theme.accentGold)
                Text("Belief Journey")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            ForEach(viewModel.checkpoints) { checkpoint in
                HStack {
                    VStack(alignment: .leading) {
                        Text(checkpoint.recordedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        if let note = checkpoint.note {
                            Text(note)
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text("\(Int(checkpoint.score))")
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Theme.scoreColor(for: checkpoint.score))
                }
                .padding(.vertical, Theme.spacingXS)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func evidenceSection(title: String, icon: String, color: Color, items: [Evidence]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("(\(items.count))")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button {
                    viewModel.showingAddEvidence = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                }
            }

            if items.isEmpty {
                Text("No evidence yet")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(items) { item in
                    EvidenceRow(evidence: item) {
                        viewModel.deleteEvidence(item)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Sheets

struct ConnectionsSheet: View {
    @ObservedObject var viewModel: BeliefDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBelief: Belief?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        Text("Link beliefs that are connected — for example, \"I'm not creative\" connects to \"Creative work is risky\".")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)

                        // Current connections
                        if !viewModel.connections.isEmpty {
                            Text("Current Connections")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            ForEach(viewModel.connections) { conn in
                                let other = viewModel.connectedBeliefs.first { $0.id == (conn.fromBeliefId == viewModel.belief.id ? conn.toBeliefId : conn.fromBeliefId) }
                                if let other = other {
                                    HStack {
                                        Text(other.text)
                                            .font(.callout)
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(2)
                                        Spacer()
                                        Button {
                                            viewModel.removeConnection(conn)
                                        } label: {
                                            Image(systemName: "link.badge.plus")
                                                .foregroundColor(Theme.accentRed)
                                        }
                                    }
                                    .padding(Theme.spacingS)
                                    .background(Theme.surfaceElevated)
                                    .cornerRadius(8)
                                }
                            }
                        }

                        // Add new connection
                        Text("Link a Belief")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)

                        let otherBeliefs = DatabaseService.shared.allBeliefs.filter { $0.id != viewModel.belief.id }
                        ForEach(otherBeliefs) { belief in
                            Button {
                                viewModel.addConnection(to: belief)
                            } label: {
                                HStack {
                                    ScoreBadge(score: belief.score)
                                    Text(belief.text)
                                        .font(.callout)
                                        .foregroundColor(Theme.textPrimary)
                                        .lineLimit(2)
                                    Spacer()
                                    Image(systemName: "link")
                                        .foregroundColor(Theme.accentBlue)
                                }
                                .padding(Theme.spacingS)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                            }
                        }

                        Spacer(minLength: Theme.spacingXL)
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CheckInSheet: View {
    @ObservedObject var viewModel: BeliefDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var checkpointNote = ""

    private let intervals = [30, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Schedule a check-in to see if this belief has shifted over time.")
                        .font(.callout)
                        .foregroundColor(Theme.textSecondary)

                    ForEach(intervals, id: \.self) { days in
                        Button {
                            viewModel.scheduleCheckIn(days: days)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(days) days")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Check back on \((Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()).formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)
                        }
                    }

                    Divider()
                        .background(Theme.border)

                    Text("Record a checkpoint now")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    TextField("Optional note about your current state...", text: $checkpointNote, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .lineLimit(2...4)

                    Button {
                        viewModel.recordCheckpoint(note: checkpointNote.isEmpty ? nil : checkpointNote)
                        dismiss()
                    } label: {
                        Text("Record Snapshot")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.spacingM)
                            .background(Theme.accentGold)
                            .foregroundColor(Theme.background)
                            .cornerRadius(12)
                    }

                    Spacer(minLength: Theme.spacingXL)
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ArchiveBeliefSheet: View {
    @ObservedObject var viewModel: BeliefDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var reason: String

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Archiving a belief marks it as \"no longer held\" — you can reflect on why here.")
                        .font(.callout)
                        .foregroundColor(Theme.textSecondary)

                    Text("Belief Obituary")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text("Why are you letting this belief go?")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    TextField("The evidence no longer supports it...", text: $reason, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .lineLimit(3...6)

                    Spacer()

                    Button {
                        viewModel.archiveBelief(reason: reason)
                        dismiss()
                    } label: {
                        Text("Archive Belief")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.spacingM)
                            .background(Theme.accentRed.opacity(0.2))
                            .foregroundColor(Theme.accentRed)
                            .cornerRadius(12)
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Archive Belief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AIAnalysisSheet: View {
    let analysis: String
    let belief: Belief
    let isLoading: Bool
    let error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: Theme.spacingM) {
                        ProgressView()
                            .tint(Theme.accentBlue)
                        Text("Analyzing your belief...")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else if let error = error {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentRed)
                        Text("Analysis Failed")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        Text(error)
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, Theme.spacingXL)
                                .padding(.vertical, Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(Theme.screenMargin)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            Text(analysis)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .textSelection(.enabled)
                        }
                        .padding(Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        BeliefDetailView(belief: .preview)
    }
    .environmentObject(DatabaseService.shared)
    .preferredColorScheme(.dark)
}
