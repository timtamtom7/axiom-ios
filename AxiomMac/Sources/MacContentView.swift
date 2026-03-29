import SwiftUI

struct MacContentView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedBelief: Belief?
    @State private var showingAddBelief = false
    @State private var selectedTab: SidebarTab = .beliefs
    @State private var beliefAppearScale: CGFloat = 0.95
    @State private var evidenceAppearOffset: CGFloat = 30

    enum SidebarTab: Hashable {
        case beliefs
        case archived
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .tint(Theme.accentGold)
        .animation(.spring(response: 0.3), value: selectedBelief?.id)
        .animation(.spring(response: 0.3), value: selectedTab)
        .keyboardShortcut("n", modifiers: .command)
        .onAppear {
            // Reset appear animations
            beliefAppearScale = 0.95
            evidenceAppearOffset = 30
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Theme.spacingS) {
                    if sortedBeliefs.isEmpty && selectedTab == .beliefs {
                        emptyBeliefsView
                    } else {
                        ForEach(sortedBeliefs) { belief in
                            MacBeliefRow(
                                belief: belief,
                                isSelected: selectedBelief?.id == belief.id,
                                appearScale: $beliefAppearScale
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedBelief = belief
                                }
                                HapticService.shared.selection()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(belief.text), score \(Int(belief.score))")
                            .accessibilityHint("Double tap to view belief details")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .padding(Theme.screenMargin)
            }

            Divider()

            addBeliefButton
        }
        .frame(minWidth: 260, idealWidth: 300)
        .background(Theme.surface)
        .navigationTitle("Beliefs")
    }

    private var emptyBeliefsView: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "brain")
                .font(.system(size: 36))
                .foregroundColor(Theme.textSecondary.opacity(0.4))

            Text("No beliefs yet")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            Text("Tap + to add your first belief")
                .font(.caption)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .padding(.vertical, Theme.spacingXL)
        .frame(maxWidth: .infinity)
    }

    private var addBeliefButton: some View {
        Button {
            HapticService.shared.selection()
            showingAddBelief = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Belief")
            }
            .font(.subheadline)
            .foregroundColor(Theme.accentGold)
            .frame(maxWidth: .infinity)
            .padding(Theme.spacingM)
        }
        .accessibilityLabel("Add new belief")
        .accessibilityHint("Opens a sheet to create a new belief")
        .keyboardShortcut("n", modifiers: .command)
        .sheet(isPresented: $showingAddBelief) {
            MacAddBeliefSheet { text, isCore, rootCause in
                let newBelief = Belief(text: text, isCore: isCore, rootCause: rootCause)
                withAnimation(.spring(response: 0.3)) {
                    databaseService.addBelief(newBelief)
                    selectedBelief = newBelief
                }
                HapticService.shared.beliefCreated()
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let belief = selectedBelief {
            MacBeliefDetailView(
                belief: belief,
                appearOffset: $evidenceAppearOffset
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
        } else {
            placeholderView
                .transition(.opacity)
        }
    }

    private var placeholderView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.spacingL) {
                Image(systemName: "scale.3d")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.textSecondary.opacity(0.2))
                    .transition(.scale(scale: 0.9))

                Text("Select a belief to examine")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)

                Text("⌘N to create a new belief")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary.opacity(0.6))
            }
        }
    }

    private var sortedBeliefs: [Belief] {
        databaseService.allBeliefs
            .filter {
                switch selectedTab {
                case .beliefs: return !$0.isArchived
                case .archived: return $0.isArchived
                }
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - MacBeliefRow

struct MacBeliefRow: View {
    let belief: Belief
    let isSelected: Bool
    @Binding var appearScale: CGFloat

    @State private var displayedScore: Double = 0
    @State private var scorePulse: CGFloat = 1.0

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            ScoreBadge(score: displayedScore)
                .scaleEffect(scorePulse)

            VStack(alignment: .leading, spacing: 2) {
                Text(belief.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Theme.spacingS) {
                    if belief.isCore {
                        Text("CORE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.accentGold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.accentGold.opacity(0.15))
                            .cornerRadius(3)
                    }
                    Text("\(belief.supportingCount) for · \(belief.contradictingCount) against")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(Theme.spacingS)
        .background(isSelected ? Theme.surfaceElevated : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Theme.accentGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(appearScale)
        .opacity(appearScale == 1 ? 1 : 0)
        .onAppear {
            // Appear animation
            withAnimation(.easeOut(duration: 0.3)) {
                appearScale = 1
            }
            // Score animate-in
            animateScore(to: belief.score)
        }
        .onChange(of: belief.score) { newValue in
            let oldValue = displayedScore
            if abs(newValue - oldValue) > 1 {
                // Pulse animation on score change
                withAnimation(.easeInOut(duration: 0.1)) {
                    scorePulse = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        scorePulse = 1.0
                    }
                }
                animateScore(to: newValue)
            }
        }
    }

    private func animateScore(to target: Double) {
        let steps = 10
        let stepDuration = 0.15 / Double(steps)
        let increment = (target - displayedScore) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    displayedScore += increment
                }
            }
        }
    }
}

// MARK: - MacBeliefDetailView

struct MacBeliefDetailView: View {
    let belief: Belief
    @EnvironmentObject var databaseService: DatabaseService
    @State private var showingAddEvidence = false
    @State private var showingDeepDive = false
    @Binding var appearOffset: CGFloat

    private var currentBelief: Belief {
        databaseService.allBeliefs.first { $0.id == belief.id } ?? belief
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                headerSection
                scoreSection
                deepDiveButton
                supportingSection
                contradictingSection
            }
            .padding(Theme.screenMargin)
        }
        .background(Theme.background)
        .navigationTitle("Belief")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticService.shared.selection()
                    showingAddEvidence = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add evidence")
                .keyboardShortcut("e", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingAddEvidence) {
            AddEvidenceView(beliefId: currentBelief.id) { text, type, confidence, url, label in
                let evidence = Evidence(
                    beliefId: currentBelief.id,
                    text: text,
                    type: type,
                    confidence: confidence,
                    sourceURL: url,
                    sourceLabel: label
                )
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    databaseService.addEvidence(evidence)
                    // Trigger slide-in for new evidence
                    appearOffset = 30
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        appearOffset = 0
                    }
                }
                HapticService.shared.evidenceAdded()
            }
        }
        .sheet(isPresented: $showingDeepDive) {
            AIDeepDiveView(belief: currentBelief)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            if currentBelief.isCore {
                Text("CORE BELIEF")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.accentGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGold.opacity(0.15))
                    .cornerRadius(4)
            }
            Text(currentBelief.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
        }
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
            }
            Spacer()
            ScoreBadge(score: currentBelief.score)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var deepDiveButton: some View {
        Button {
            HapticService.shared.selection()
            showingDeepDive = true
        } label: {
            Label("AI Deep Dive", systemImage: "bubble.left.and.bubble.right")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingS)
                .background(Theme.accentBlue.opacity(0.15))
                .foregroundColor(Theme.accentBlue)
                .cornerRadius(8)
        }
        .accessibilityLabel("AI Deep Dive")
        .accessibilityHint("Opens an AI-powered conversation to examine this belief")
    }

    private var supportingSection: some View {
        evidenceSection(
            title: "Supporting",
            icon: "checkmark.circle.fill",
            color: Theme.accentGreen,
            items: currentBelief.evidenceItems.filter { $0.type == .support }
        )
    }

    private var contradictingSection: some View {
        evidenceSection(
            title: "Contradicting",
            icon: "xmark.circle.fill",
            color: Theme.accentRed,
            items: currentBelief.evidenceItems.filter { $0.type == .contradict }
        )
    }

    private var scoreDescription: String {
        if currentBelief.score < 40 {
            return "Evidence leans against this belief"
        } else if currentBelief.score < 70 {
            return "Evidence is mixed"
        } else {
            return "Evidence supports this belief"
        }
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
            }

            if items.isEmpty {
                Text("No evidence yet")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(items) { item in
                    MacEvidenceRow(evidence: item)
                        .offset(x: appearOffset)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: appearOffset)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

// MARK: - MacEvidenceRow

struct MacEvidenceRow: View {
    let evidence: Evidence

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text(evidence.text)
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3)

            HStack {
                confidenceIndicator
                Spacer()
                sourceLabel
                dateLabel
            }
        }
        .padding(Theme.spacingS)
        .background(Theme.surfaceElevated)
        .cornerRadius(8)
    }

    private var confidenceIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(confidenceDotColor(for: i))
                    .frame(width: 6, height: 6)
            }
            Text(evidence.confidenceLabel)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var sourceLabel: some View {
        if let label = evidence.sourceLabel {
            HStack(spacing: 2) {
                Image(systemName: "link")
                    .font(.caption2)
                Text(label)
                    .lineLimit(1)
            }
            .font(.caption2)
            .foregroundColor(Theme.accentBlue)
        }
    }

    private var dateLabel: some View {
        Text(evidence.createdAt.formatted(date: .abbreviated, time: .omitted))
            .font(.caption2)
            .foregroundColor(Theme.textSecondary)
    }

    private func confidenceDotColor(for index: Int) -> Color {
        let thresholds = [0.3, 0.6, 0.9]
        let filled = evidence.confidence >= thresholds[index]
        if evidence.confidence >= 0.7 {
            return filled ? Theme.accentGreen : Theme.border
        } else if evidence.confidence >= 0.4 {
            return filled ? Theme.accentGold : Theme.border
        } else {
            return filled ? Theme.accentRed : Theme.border
        }
    }
}

// MARK: - MacAddBeliefSheet

struct MacAddBeliefSheet: View {
    let onSave: (String, Bool, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var beliefText = ""
    @State private var isCore = false
    @State private var rootCause = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    TextField("I believe that...", text: $beliefText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .lineLimit(2...4)

                    Toggle(isOn: $isCore) {
                        HStack {
                            Image(systemName: "diamond.fill")
                                .foregroundColor(Theme.accentGold)
                            Text("Mark as Core Belief")
                                .font(.subheadline)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    .tint(Theme.accentGold)

                    originField

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("New Belief")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                        .keyboardShortcut(.escape)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let label = rootCause.isEmpty ? nil : rootCause
                        onSave(beliefText, isCore, label)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(beliefText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
    }

    private var originField: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text("Origin (optional)")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            TextField("e.g. Childhood experience, Trauma...", text: $rootCause)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacingS)
                .background(Theme.surface)
                .cornerRadius(8)
        }
    }
}
