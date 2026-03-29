import SwiftUI

/// macOS belief evolution view showing timeline, reason badges, consistency score, and reminders.
struct MacBeliefEvolutionView: View {
    let belief: Belief
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.dismiss) private var dismiss
    @State private var checkpoints: [BeliefCheckpoint] = []
    @State private var showingRecordSheet = false
    @State private var showingReminderSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        beliefHeader
                        consistencySection
                        timelineSection
                        remindersSection
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Belief Evolution")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingRecordSheet = true } label: {
                            Label("Record Checkpoint", systemImage: "clock")
                        }
                        Button { showingReminderSheet = true } label: {
                            Label("Set Reminder", systemImage: "bell")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadCheckpoints() }
            .sheet(isPresented: $showingRecordSheet) {
                MacRecordCheckpointSheet(beliefId: belief.id) { loadCheckpoints() }
            }
            .sheet(isPresented: $showingReminderSheet) {
                MacMonthlyReminderSheet(belief: belief)
            }
        }
    }

    private var beliefHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                if belief.isCore {
                    Text("CORE BELIEF")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accentGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accentGold.opacity(0.15))
                        .cornerRadius(4)
                }
                Spacer()
                ScoreBadge(score: belief.score)
            }
            Text(belief.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(Theme.accentBlue)
                Text("Belief Consistency Score")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            HStack(spacing: Theme.spacingL) {
                ConsistencyGauge(score: consistencyScore)
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(consistencyDescription)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Text(consistencySubtext)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            if let origin = belief.rootCause {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundColor(Theme.accentGold)
                    Text("Origin: \(origin)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(Theme.accentGold)
                Text("Score Timeline")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button { showingRecordSheet = true } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Theme.accentGold)
                }
                .accessibilityLabel("Record new checkpoint")
                .accessibilityHint("Opens a sheet to record a new score checkpoint")
            }

            if sortedCheckpoints.count >= 2 {
                evolutionChart
                Divider()
                checkpointTimeline
            } else {
                VStack(spacing: Theme.spacingM) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    Text("Record at least 2 checkpoints to see your belief's journey")
                        .font(.callout)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button { showingRecordSheet = true } label: {
                        Text("Record First Checkpoint")
                            .font(.subheadline)
                            .padding(.horizontal, Theme.spacingL)
                            .padding(.vertical, Theme.spacingS)
                            .background(Theme.accentGold.opacity(0.15))
                            .foregroundColor(Theme.accentGold)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingL)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var evolutionChart: some View {
        let sorted = sortedCheckpoints
        return VStack(spacing: Theme.spacingS) {
            HStack(alignment: .bottom, spacing: Theme.spacingS) {
                VStack(alignment: .leading) {
                    if let first = sorted.first {
                        Text("\(Int(first.score))")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textSecondary)
                        Text("Start")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .frame(width: 40)

                GeometryReader { geo in
                    let scores = sorted.map { $0.score }
                    let minScore = (scores.min() ?? 0) - 5
                    let maxScore = (scores.max() ?? 100) + 5
                    let range = max(maxScore - minScore, 1)
                    Path { path in
                        for (i, cp) in sorted.enumerated() {
                            let x = geo.size.width * CGFloat(i) / CGFloat(max(sorted.count - 1, 1))
                            let normalized = (cp.score - minScore) / range
                            let y = geo.size.height * (1 - normalized)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Theme.accentGold, lineWidth: 2)
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { i, cp in
                        let x = geo.size.width * CGFloat(i) / CGFloat(max(sorted.count - 1, 1))
                        let normalized = (cp.score - minScore) / range
                        let y = geo.size.height * (1 - normalized)
                        Circle()
                            .fill(Theme.accentGold)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
                .frame(height: 80)

                VStack(alignment: .trailing) {
                    if let last = sorted.last {
                        Text("\(Int(last.score))")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.scoreColor(for: last.score))
                        Text("Now")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .frame(width: 40)
            }
        }
    }

    private var checkpointTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedCheckpoints.enumerated()), id: \.element.id) { index, cp in
                HStack(alignment: .top, spacing: Theme.spacingM) {
                    VStack {
                        Circle()
                            .fill(index == 0 ? Theme.textSecondary : Theme.accentGold)
                            .frame(width: 10, height: 10)
                        if index < sortedCheckpoints.count - 1 {
                            Rectangle()
                                .fill(Theme.border)
                                .frame(width: 1, height: 30)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(cp.recordedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("\(Int(cp.score))")
                                .font(.system(.callout, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.scoreColor(for: cp.score))
                        }
                        if let note = cp.note, !note.isEmpty {
                            Text("\"\(note)\"")
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                                .italic()
                        }
                        ReasonBadge(reason: reasonForCheckpoint(cp))
                    }
                }
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(Theme.accentGold)
                Text("Monthly Review Reminders")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            if let nextCheckIn = belief.checkInScheduledAt {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.accentBlue)
                    Text("Next review: \(nextCheckIn.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    if let interval = belief.checkInIntervalDays {
                        Text("Every \(interval) days")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(Theme.spacingS)
                .background(Theme.accentBlue.opacity(0.1))
                .cornerRadius(8)
            } else {
                VStack(spacing: Theme.spacingS) {
                    Text("Set up monthly reminders to check in on this belief's evolution.")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Button { showingReminderSheet = true } label: {
                        Text("Set Reminder")
                            .font(.subheadline)
                            .padding(.horizontal, Theme.spacingL)
                            .padding(.vertical, Theme.spacingS)
                            .background(Theme.accentGold.opacity(0.15))
                            .foregroundColor(Theme.accentGold)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var sortedCheckpoints: [BeliefCheckpoint] {
        checkpoints.sorted { $0.recordedAt < $1.recordedAt }
    }

    private var consistencyScore: Double {
        guard sortedCheckpoints.count >= 2 else { return 0 }
        let scores = sortedCheckpoints.map { $0.score }
        let avg = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - avg, 2) }.reduce(0, +) / Double(scores.count)
        let stdDev = sqrt(variance)
        return max(0, min(100, 100 - stdDev * 2))
    }

    private var consistencyDescription: String {
        if consistencyScore >= 80 { return "Highly consistent belief" }
        else if consistencyScore >= 60 { return "Moderately consistent" }
        else if consistencyScore >= 40 { return "Somewhat variable" }
        else { return "Highly variable — worth examining" }
    }

    private var consistencySubtext: String {
        if sortedCheckpoints.count < 2 {
            return "Record more checkpoints to calculate consistency"
        }
        return "Based on \(sortedCheckpoints.count) recorded checkpoints"
    }

    private func loadCheckpoints() {
        checkpoints = databaseService.checkpointsFor(beliefId: belief.id)
    }

    private func reasonForCheckpoint(_ cp: BeliefCheckpoint) -> String {
        if let note = cp.note?.lowercased() {
            if note.contains("evidence") { return "New evidence" }
            if note.contains("debate") || note.contains("changed") { return "Debate changed mind" }
            if note.contains("growth") || note.contains("personal") { return "Personal growth" }
        }
        return "Checkpoint recorded"
    }
}

// MARK: - ConsistencyGauge

struct ConsistencyGauge: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.border, lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(score / 100))
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(score))")
                    .font(.system(size: 20, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                Text("consistency")
                    .font(.system(size: 8))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(width: 70, height: 70)
    }

    private var gaugeColor: Color {
        if score >= 80 { return Theme.accentGreen }
        else if score >= 60 { return Theme.accentGold }
        else if score >= 40 { return Theme.accentBlue }
        else { return Theme.accentRed }
    }
}

// MARK: - ReasonBadge

struct ReasonBadge: View {
    let reason: String

    private var color: Color {
        if reason.contains("evidence") { return Theme.accentBlue }
        if reason.contains("Debate") || reason.contains("changed") { return Theme.accentGold }
        if reason.contains("growth") || reason.contains("Personal") { return Theme.accentGreen }
        return Theme.textSecondary
    }

    var body: some View {
        Text(reason)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - MacRecordCheckpointSheet

struct MacRecordCheckpointSheet: View {
    let beliefId: UUID
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @State private var score: Double = 50
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Record your current confidence in this belief.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        HStack {
                            Text("Score")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(Int(score))")
                                .font(.system(size: 36, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.scoreColor(for: score))
                        }

                        Slider(value: $score, in: 0...100, step: 1)
                            .tint(Theme.scoreColor(for: score))
                            .accessibilityLabel("Belief strength, \(Int(score)) percent. Drag left or right to adjust.")

                        HStack {
                            Text("Disagree")
                                .font(.caption)
                                .foregroundColor(Theme.accentRed)
                            Spacer()
                            Text("Agree")
                                .font(.caption)
                                .foregroundColor(Theme.accentGreen)
                        }
                    }

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        Text("Note (optional)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("What led to this score?", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                            .padding(Theme.spacingS)
                            .background(Theme.surface)
                            .cornerRadius(8)
                            .lineLimit(2...4)
                    }

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Record Checkpoint")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let checkpoint = BeliefCheckpoint(
                            beliefId: beliefId,
                            score: score,
                            note: note.isEmpty ? nil : note
                        )
                        databaseService.addCheckpoint(checkpoint)
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - MacMonthlyReminderSheet

struct MacMonthlyReminderSheet: View {
    let belief: Belief
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedInterval: Int = 30

    private let intervals = [7, 14, 30, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Set a recurring reminder to review this belief and record a checkpoint.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Review Interval")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)

                        ForEach(intervals, id: \.self) { interval in
                            Button {
                                selectedInterval = interval
                            } label: {
                                HStack {
                                    Text(intervalLabel(interval))
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    if selectedInterval == interval {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.accentGold)
                                    }
                                }
                                .padding(Theme.spacingS)
                                .background(selectedInterval == interval ? Theme.accentGold.opacity(0.1) : Theme.surface)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("You'll be reminded to review this belief every \(intervalLabel(selectedInterval).lowercased()).")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Set Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        var updated = belief
                        updated.scheduleCheckIn(days: selectedInterval)
                        databaseService.updateBelief(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func intervalLabel(_ days: Int) -> String {
        if days == 7 { return "Weekly" }
        else if days == 14 { return "Every 2 weeks" }
        else if days == 30 { return "Monthly" }
        else if days == 60 { return "Every 2 months" }
        else { return "Every 3 months" }
    }
}

#Preview {
    MacBeliefEvolutionView(belief: .preview)
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
