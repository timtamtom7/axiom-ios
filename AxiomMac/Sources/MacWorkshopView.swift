import SwiftUI

// MARK: - Workshop Models

struct Workshop: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var exercises: [WorkshopExercise]
    var isBuiltIn: Bool

    init(id: UUID = UUID(), title: String, description: String, exercises: [WorkshopExercise], isBuiltIn: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.exercises = exercises
        self.isBuiltIn = isBuiltIn
    }

    static let builtInWorkshops: [Workshop] = [
        Workshop(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Overcoming Imposter Syndrome",
            description: "Challenge the belief that you don't belong or aren't qualified enough",
            exercises: [
                WorkshopExercise(id: UUID(), title: "Recognize Your Wins", instructions: "List 3 accomplishments that prove you belong. Don't minimize them.", durationSeconds: 180, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Evidence Collection", instructions: "Write down feedback or proof that you've earned your place.", durationSeconds: 300, type: .guided),
                WorkshopExercise(id: UUID(), title: "Reframe Exercise", instructions: "Take your imposter thought and write a more balanced alternative.", durationSeconds: 240, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Share with Partner", instructions: "Pair up and share one win you're proud of. Practice accepting compliments.", durationSeconds: 300, type: .group),
                WorkshopExercise(id: UUID(), title: "Quiz: Common Traps", instructions: "Identify cognitive distortions in common imposter thoughts.", durationSeconds: 120, type: .quiz),
            ],
            isBuiltIn: true
        ),
        Workshop(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Building Self-Compassion",
            description: "Develop a kinder inner voice and respond to struggles with understanding",
            exercises: [
                WorkshopExercise(id: UUID(), title: "Self-Criticism Audit", instructions: "Notice your inner critic for 2 minutes. What is it saying?", durationSeconds: 120, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Letter to Yourself", instructions: "Write a letter to yourself as if you were a compassionate friend.", durationSeconds: 300, type: .guided),
                WorkshopExercise(id: UUID(), title: "Common Humanity", instructions: "Reflect: What would you tell a friend going through the same thing?", durationSeconds: 180, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Mindful Self-Compassion Break", instructions: "Practice the MSC break: This is a moment of suffering → Suffering is part of life → May I be kind to myself.", durationSeconds: 240, type: .guided),
            ],
            isBuiltIn: true
        ),
        Workshop(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "Letting Go of Perfectionism",
            description: "Shift from 'perfect or nothing' to 'good enough is great'",
            exercises: [
                WorkshopExercise(id: UUID(), title: "Perfectionism Cost-Benefit", instructions: "What has perfectionism cost you? What benefits does it give you (even if flawed)?", durationSeconds: 180, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Good Enough Test", instructions: "Think of a recent task. Was 'good enough' actually good enough? What happened?", durationSeconds: 240, type: .reflection),
                WorkshopExercise(id: UUID(), title: "Challenge the All-or-Nothing", instructions: "Identify an 'all or nothing' belief. Write a more nuanced version.", durationSeconds: 180, type: .guided),
                WorkshopExercise(id: UUID(), title: "Intentional 'Good Enough'", instructions: "Today, deliberately do one task at 80% effort. Notice what happens.", durationSeconds: 120, type: .group),
                WorkshopExercise(id: UUID(), title: "Reframe Quiz", instructions: "Match imperfect situations with balanced reframes.", durationSeconds: 180, type: .quiz),
            ],
            isBuiltIn: true
        ),
    ]
}

struct WorkshopExercise: Identifiable, Codable {
    let id: UUID
    var title: String
    var instructions: String
    var durationSeconds: Int
    var type: ExerciseType

    init(id: UUID = UUID(), title: String, instructions: String, durationSeconds: Int, type: ExerciseType) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.durationSeconds = durationSeconds
        self.type = type
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case reflection
    case guided
    case group
    case quiz

    var icon: String {
        switch self {
        case .reflection: return "brain.head.profile"
        case .guided: return "figure.walk"
        case .group: return "person.3.fill"
        case .quiz: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .reflection: return Theme.accentBlue
        case .guided: return Theme.accentGreen
        case .group: return Theme.accentGold
        case .quiz: return Theme.accentRed
        }
    }
}

struct WorkshopOutcome: Identifiable, Codable {
    let id: UUID
    var workshopId: UUID
    var participantId: UUID
    var beliefId: UUID?
    var beforeScore: Double
    var afterScore: Double
    var completedAt: Date

    init(id: UUID = UUID(), workshopId: UUID, participantId: UUID, beliefId: UUID? = nil, beforeScore: Double, afterScore: Double, completedAt: Date = Date()) {
        self.id = id
        self.workshopId = workshopId
        self.participantId = participantId
        self.beliefId = beliefId
        self.beforeScore = beforeScore
        self.afterScore = afterScore
        self.completedAt = completedAt
    }

    var improvement: Double { afterScore - beforeScore }
}

// MARK: - MacWorkshopView

@MainActor
struct MacWorkshopView: View {
    @State private var selectedTab: WorkshopTab = .library
    @State private var selectedWorkshop: Workshop?
    @State private var isPlaying = false
    @State private var outcomes: [WorkshopOutcome] = []

    enum WorkshopTab: String, CaseIterable {
        case library = "Workshop Library"
        case player = "Workshop Player"
        case facilitator = "Facilitator"
        case outcomes = "Outcomes"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .background(Theme.background)
        .onAppear {
            loadOutcomes()
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(WorkshopTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(selectedTab == tab ? Theme.accentGold.opacity(0.15) : Color.clear)
                            .cornerRadius(Theme.cornerRadiusS)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.rawValue)
                    .accessibilityAddTraits(selectedTab == tab ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, Theme.spacingS)
        }
        .background(Theme.surface)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .library:
            workshopLibraryView
        case .player:
            workshopPlayerView
        case .facilitator:
            facilitatorView
        case .outcomes:
            outcomesView
        }
    }

    // MARK: - Workshop Library

    private var workshopLibraryView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pre-Built Workshops")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(Workshop.builtInWorkshops.count) workshops")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            ScrollView {
                LazyVStack(spacing: Theme.spacingM) {
                    ForEach(Workshop.builtInWorkshops) { workshop in
                        WorkshopLibraryCard(workshop: workshop) {
                            selectedWorkshop = workshop
                            selectedTab = .player
                        }
                    }
                }
                .padding(Theme.screenMargin)
            }
        }
    }

    // MARK: - Workshop Player

    private var workshopPlayerView: some View {
        VStack(spacing: 0) {
            if let workshop = selectedWorkshop {
                WorkshopPlayerContent(workshop: workshop, isPlaying: $isPlaying, onComplete: { before, after in
                    let outcome = WorkshopOutcome(workshopId: workshop.id, participantId: UUID(), beforeScore: before, afterScore: after)
                    outcomes.append(outcome)
                    saveOutcomes()
                })
            } else {
                emptyPlayerView
            }
        }
    }

    private var emptyPlayerView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            VStack(spacing: Theme.spacingS) {
                Text("No Workshop Selected")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text("Choose a workshop from the library to get started")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
            }
            Button {
                selectedTab = .library
            } label: {
                Text("Browse Library")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accentGold)
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS)
                    .background(Theme.accentGold.opacity(0.15))
                    .cornerRadius(Theme.cornerRadiusPill)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Facilitator Mode

    private var facilitatorView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Facilitator Mode")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button {
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accentGreen)
                }
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    FacilitatorWorkshopPicker()

                    FacilitatorParticipantsCard()

                    FacilitatorControlsCard()
                }
                .padding(Theme.screenMargin)
            }
        }
    }

    // MARK: - Outcomes

    private var outcomesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Workshop Outcomes")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(outcomes.count) recorded")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if outcomes.isEmpty {
                VStack(spacing: Theme.spacingL) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.textSecondary.opacity(0.3))
                    VStack(spacing: Theme.spacingS) {
                        Text("No Outcomes Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textPrimary)
                        Text("Complete workshops to track your belief score changes")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(outcomes) { outcome in
                            OutcomeCard(outcome: outcome)
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
        }
    }

    private func loadOutcomes() {
        if let data = UserDefaults.standard.data(forKey: "workshopOutcomes"),
           let decoded = try? JSONDecoder().decode([WorkshopOutcome].self, from: data) {
            outcomes = decoded
        }
    }

    private func saveOutcomes() {
        if let encoded = try? JSONEncoder().encode(outcomes) {
            UserDefaults.standard.set(encoded, forKey: "workshopOutcomes")
        }
    }
}

// MARK: - Workshop Library Card

struct WorkshopLibraryCard: View {
    let workshop: Workshop
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(workshop.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(workshop.description)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.spacingXS) {
                    Text("\(workshop.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(totalDuration)
                        .font(.caption)
                        .foregroundColor(Theme.accentBlue)
                }
            }

            HStack(spacing: Theme.spacingS) {
                ForEach(exerciseTypeCounts.keys.sorted(by: { exerciseTypeCounts[$0]! > exerciseTypeCounts[$1]! }), id: \.self) { type in
                    if let count = exerciseTypeCounts[type], count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption2)
                            Text("\(count)")
                                .font(.caption2)
                        }
                        .foregroundColor(type.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(type.color.opacity(0.15))
                        .cornerRadius(4)
                    }
                }
                Spacer()
                Button {
                    onStart()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.accentGreen)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingXS)
                        .background(Theme.accentGreen.opacity(0.15))
                        .cornerRadius(Theme.cornerRadiusPill)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }

    private var exerciseTypeCounts: [ExerciseType: Int] {
        var counts: [ExerciseType: Int] = [:]
        for exercise in workshop.exercises {
            counts[exercise.type, default: 0] += 1
        }
        return counts
    }

    private var totalDuration: String {
        let total = workshop.exercises.reduce(0) { $0 + $1.durationSeconds }
        let minutes = total / 60
        return "~\(minutes) min"
    }
}

// MARK: - Workshop Player Content

struct WorkshopPlayerContent: View {
    let workshop: Workshop
    @Binding var isPlaying: Bool
    let onComplete: (Double, Double) -> Void

    @State private var currentExerciseIndex = 0
    @State private var timeRemaining: Int = 0
    @State private var timerActive = false
    @State private var showingBeforeScore = false
    @State private var showingAfterScore = false
    @State private var beforeScore: Double = 50
    @State private var afterScore: Double = 50

    private var currentExercise: WorkshopExercise? {
        guard currentExerciseIndex < workshop.exercises.count else { return nil }
        return workshop.exercises[currentExerciseIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(workshop.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(currentExerciseIndex + 1) / \(workshop.exercises.count)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.screenMargin)
            .background(Theme.surface)

            if !isPlaying && currentExerciseIndex == 0 && !showingBeforeScore {
                preWorkshopView
            } else if showingBeforeScore {
                beforeScoreView
            } else if currentExercise != nil {
                exercisePlayerView
            } else {
                completionView
            }
        }
        .onAppear {
            if let exercise = currentExercise {
                timeRemaining = exercise.durationSeconds
            }
        }
    }

    private var preWorkshopView: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()
            VStack(spacing: Theme.spacingM) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.accentGold)
                Text("Before We Begin")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                Text("Rate your current belief strength about:\n\"\(workshop.description)\"")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ScoreSlider(score: $beforeScore)
                .padding(.horizontal, Theme.screenMargin)

            Button {
                showingBeforeScore = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingBeforeScore = false
                    isPlaying = true
                }
            } label: {
                Text("Start Workshop")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(Theme.accentGold)
                    .cornerRadius(Theme.cornerRadiusM)
            }
            .padding(.horizontal, Theme.screenMargin)

            Spacer()
        }
    }

    private var beforeScoreView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Text("Recording your starting point...")
                .font(.title3)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }

    private var exercisePlayerView: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.surface)
                    Rectangle()
                        .fill(Theme.accentGold.opacity(0.3))
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)

            ScrollView {
                VStack(spacing: Theme.spacingXL) {
                    if let exercise = currentExercise {
                        // Exercise type badge
                        HStack {
                            Image(systemName: exercise.type.icon)
                                .font(.caption)
                            Text(exercise.type.rawValue.capitalized)
                                .font(.caption)
                        }
                        .foregroundColor(exercise.type.color)
                        .padding(.horizontal, Theme.spacingS)
                        .padding(.vertical, Theme.spacingXS)
                        .background(exercise.type.color.opacity(0.15))
                        .cornerRadius(Theme.cornerRadiusS)

                        Text(exercise.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text(exercise.instructions)
                            .font(.body)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacingL)

                        // Timer
                        if timerActive || timeRemaining > 0 {
                            TimerView(seconds: $timeRemaining, isActive: $timerActive)
                        }
                    }
                }
                .padding(.vertical, Theme.spacingXL)
            }

            // Controls
            HStack(spacing: Theme.spacingM) {
                Button {
                    if currentExerciseIndex > 0 {
                        currentExerciseIndex -= 1
                        if let exercise = currentExercise {
                            timeRemaining = exercise.durationSeconds
                            timerActive = false
                        }
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(Theme.textSecondary)
                }
                .disabled(currentExerciseIndex == 0)

                Button {
                    timerActive.toggle()
                } label: {
                    Image(systemName: timerActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.accentGold)
                }

                Button {
                    if currentExerciseIndex < workshop.exercises.count - 1 {
                        currentExerciseIndex += 1
                        if let exercise = currentExercise {
                            timeRemaining = exercise.durationSeconds
                            timerActive = false
                        }
                    } else {
                        isPlaying = false
                        showingAfterScore = true
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(Theme.spacingL)
            .background(Theme.surface)
        }
    }

    private var completionView: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()
            VStack(spacing: Theme.spacingM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.accentGreen)
                Text("Workshop Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
            }

            if showingAfterScore {
                ScoreSlider(score: $afterScore)
                    .padding(.horizontal, Theme.screenMargin)

                Button {
                    onComplete(beforeScore, afterScore)
                    showingAfterScore = false
                } label: {
                    Text("Save & Finish")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingM)
                        .background(Theme.accentGreen)
                        .cornerRadius(Theme.cornerRadiusM)
                }
                .padding(.horizontal, Theme.screenMargin)
            }

            Spacer()
        }
    }

    private var progress: CGFloat {
        guard !workshop.exercises.isEmpty else { return 0 }
        return CGFloat(currentExerciseIndex + 1) / CGFloat(workshop.exercises.count)
    }
}

// MARK: - Score Slider

struct ScoreSlider: View {
    @Binding var score: Double

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            HStack {
                Text("Low")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Int(score))%")
                    .font(.headline)
                    .foregroundColor(Theme.scoreColor(for: score))
                Spacer()
                Text("High")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Slider(value: $score, in: 0...100, step: 5)
                .tint(Theme.scoreColor(for: score))

            HStack {
                Circle()
                    .fill(Theme.accentRed)
                    .frame(width: 12, height: 12)
                Spacer()
                Circle()
                    .fill(Theme.accentGold)
                    .frame(width: 12, height: 12)
                Spacer()
                Circle()
                    .fill(Theme.accentGreen)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Timer View

struct TimerView: View {
    @Binding var seconds: Int
    @Binding var isActive: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(seconds < 10 ? Theme.accentRed : Theme.textPrimary)

            Button {
                isActive.toggle()
            } label: {
                Image(systemName: isActive ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(Theme.accentGold)
            }
        }
        .onReceive(timer) { _ in
            if isActive && seconds > 0 {
                seconds -= 1
            } else if seconds == 0 {
                isActive = false
            }
        }
    }

    private var formattedTime: String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Facilitator Views

struct FacilitatorWorkshopPicker: View {
    @State private var selectedWorkshop: Workshop? = Workshop.builtInWorkshops.first

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Select Workshop")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacingS) {
                    ForEach(Workshop.builtInWorkshops) { workshop in
                        Button {
                            selectedWorkshop = workshop
                        } label: {
                            Text(workshop.title)
                                .font(.caption)
                                .foregroundColor(selectedWorkshop?.id == workshop.id ? Theme.textPrimary : Theme.textSecondary)
                                .padding(.horizontal, Theme.spacingM)
                                .padding(.vertical, Theme.spacingS)
                                .background(selectedWorkshop?.id == workshop.id ? Theme.accentGold.opacity(0.15) : Theme.surfaceElevated)
                                .cornerRadius(Theme.cornerRadiusPill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

struct FacilitatorParticipantsCard: View {
    @State private var participantCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                HStack(spacing: Theme.spacingS) {
                    Button {
                        if participantCount > 1 { participantCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text("\(participantCount)")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Button {
                        if participantCount < 20 { participantCount += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.accentGold)
                    }
                }
            }

            HStack(spacing: -8) {
                ForEach(0..<min(participantCount, 8), id: \.self) { index in
                    Circle()
                        .fill(Theme.accentBlue.opacity(0.3 + Double(index) * 0.08))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("P\(index + 1)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.surface, lineWidth: 2)
                        )
                }
                if participantCount > 8 {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("+\(participantCount - 8)")
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                        )
                }
                Spacer()
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

struct FacilitatorControlsCard: View {
    @State private var isRunning = false
    @State private var currentStep = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Session Controls")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Theme.spacingM) {
                Button {
                    isRunning.toggle()
                } label: {
                    Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingS)
                        .background(isRunning ? Theme.accentGold : Theme.accentGreen)
                        .cornerRadius(8)
                }

                Button {
                    currentStep = max(0, currentStep - 1)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 50)
                        .padding(Theme.spacingS)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(8)
                }

                Button {
                    currentStep += 1
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 50)
                        .padding(Theme.spacingS)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(8)
                }
            }

            Text("Step \(currentStep + 1) of 5")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

// MARK: - Outcome Card

struct OutcomeCard: View {
    let outcome: WorkshopOutcome

    private var workshopTitle: String {
        Workshop.builtInWorkshops.first { $0.id == outcome.workshopId }?.title ?? "Workshop"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text(workshopTitle)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(outcome.completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: Theme.spacingL) {
                VStack(spacing: Theme.spacingXS) {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(outcome.beforeScore))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accentRed)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(Theme.textSecondary)

                VStack(spacing: Theme.spacingXS) {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(outcome.afterScore))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accentGreen)
                }

                Spacer()

                VStack(spacing: Theme.spacingXS) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(outcome.improvement >= 0 ? "+\(Int(outcome.improvement))%" : "\(Int(outcome.improvement))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(outcome.improvement >= 0 ? Theme.accentGreen : Theme.accentRed)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusM)
    }
}
