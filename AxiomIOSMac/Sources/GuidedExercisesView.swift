import SwiftUI

// MARK: - Exercise Types

enum GuidedExerciseType: String, CaseIterable, Identifiable {
    case decatastrophizing = "Decatastrophizing"
    case probabilityReestimation = "Probability Re-estimation"
    case evidenceWeighing = "Evidence Weighing"
    case behavioralActivation = "Behavioral Activation"
    case exposureLadder = "Exposure Ladder"
    case beliefRestructuring = "Belief Restructuring"
    case breathing = "4-7-8 Breathing"
    case grounding = "5-4-3-2-1 Grounding"
    case bodyScan = "Body Scan"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .decatastrophizing:
            return "Challenge catastrophic thinking by estimating realistic outcomes"
        case .probabilityReestimation:
            return "Reframe probability estimates for anxious predictions"
        case .evidenceWeighing:
            return "Balance evidence for and against a belief"
        case .behavioralActivation:
            return "gentle activities to counter avoidance"
        case .exposureLadder:
            return "Build a hierarchy of feared situations"
        case .beliefRestructuring:
            return "Identify and challenge distorted thinking patterns"
        case .breathing:
            return "Calm your nervous system with guided breathing"
        case .grounding:
            return "Anchor yourself through the 5-4-3-2-1 sensory exercise"
        case .bodyScan:
            return "Progressive relaxation from head to toe"
        }
    }

    var estimatedMinutes: Int {
        switch self {
        case .breathing, .grounding: return 3
        case .bodyScan: return 10
        case .beliefRestructuring: return 15
        case .decatastrophizing, .probabilityReestimation, .evidenceWeighing: return 10
        case .behavioralActivation, .exposureLadder: return 15
        }
    }

    var icon: String {
        switch self {
        case .decatastrophizing: return "exclamationmark.triangle"
        case .probabilityReestimation: return "chart.bar"
        case .evidenceWeighing: return "scale.3d"
        case .behavioralActivation: return "figure.walk"
        case .exposureLadder: return "ladder"
        case .beliefRestructuring: return "brain"
        case .breathing: return "wind"
        case .grounding: return "hand.raised"
        case .bodyScan: return "person"
        }
    }
}

struct GuidedExercise: Identifiable, Codable {
    let id: UUID
    let type: GuidedExerciseType
    var title: String
    var currentStep: Int
    var totalSteps: Int
    var isCompleted: Bool
    let createdAt: Date
    var completedAt: Date?
    var steps: [GuidedExerciseStep]
    var linkedBeliefId: UUID?
    var assignedByTherapist: Bool
}

struct GuidedExerciseStep: Identifiable, Codable {
    let id: UUID
    let title: String
    let prompt: String
    var userInput: String
    var isComplete: Bool
}

struct ExerciseCompletion: Codable, Identifiable {
    let id: UUID
    let exerciseId: UUID
    let completedAt: Date
    let type: GuidedExerciseType
    let durationSeconds: Int
}

// MARK: - Guided Exercises View

struct GuidedExercisesView: View {
    @State private var exercises: [GuidedExercise] = []
    @State private var selectedExercise: GuidedExercise?
    @State private var showingExerciseSheet = false
    @State private var activeTab: ExerciseTab = .all

    enum ExerciseTab: String, CaseIterable {
        case all = "All"
        case breathing = "Breathing"
        case cognitive = "Cognitive"
        case assigned = "Assigned"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabSelector
                exerciseList
            }
            .navigationTitle("Guided Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingExerciseSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingExerciseSheet) {
                ExercisePickerView(onSelect: { type in
                    startExercise(type: type)
                })
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseSessionView(
                    exercise: exercise,
                    onUpdate: { updated in
                        if let idx = exercises.firstIndex(where: { $0.id == updated.id }) {
                            exercises[idx] = updated
                        }
                    },
                    onComplete: { completed in
                        if completed {
                            markComplete(exercise)
                        }
                        selectedExercise = nil
                    }
                )
            }
            .onAppear {
                loadExercises()
            }
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExerciseTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(_ tab: ExerciseTab) -> some View {
        Button {
            activeTab = tab
        } label: {
            Text(tab.rawValue)
                .font(.subheadline)
                .fontWeight(activeTab == tab ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    activeTab == tab
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                )
                .foregroundColor(activeTab == tab ? .accentColor : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filteredExercises: [GuidedExercise] {
        switch activeTab {
        case .all:
            return exercises
        case .breathing:
            return exercises.filter { [GuidedExerciseType.breathing, GuidedExerciseType.grounding, GuidedExerciseType.bodyScan].contains($0.type) }
        case .cognitive:
            return exercises.filter { [GuidedExerciseType.decatastrophizing, GuidedExerciseType.probabilityReestimation, GuidedExerciseType.evidenceWeighing, GuidedExerciseType.beliefRestructuring].contains($0.type) }
        case .assigned:
            return exercises.filter { $0.assignedByTherapist }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                ExerciseRowView(exercise: exercise)
                    .onTapGesture {
                        selectedExercise = exercise
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func startExercise(type: GuidedExerciseType) {
        let steps = generateSteps(for: type)
        let exercise = GuidedExercise(
            id: UUID(),
            type: type,
            title: type.rawValue,
            currentStep: 0,
            totalSteps: steps.count,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil,
            steps: steps,
            linkedBeliefId: nil,
            assignedByTherapist: false
        )
        exercises.insert(exercise, at: 0)
        selectedExercise = exercise
        saveExercises()
    }

    private func markComplete(_ exercise: GuidedExercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        exercises[index].isCompleted = true
        exercises[index].completedAt = Date()
        saveExercises()
    }

    private func generateSteps(for type: GuidedExerciseType) -> [GuidedExerciseStep] {
        switch type {
        case .beliefRestructuring:
            return [
                GuidedExerciseStep(id: UUID(), title: "Identify the Belief", prompt: "What belief would you like to examine? Write it as a specific thought.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Notice Your Feelings", prompt: "What emotions arise when you think about this belief? Rate their intensity 0-100.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Find the Distortion", prompt: "Which thinking pattern might be at play?\n• All-or-Nothing\n• Catastrophizing\n• Mind Reading\n• Fortune Telling\n• Emotional Reasoning", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Gather Evidence", prompt: "What evidence supports this belief? Be specific and objective.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Find Counter-Evidence", prompt: "What evidence contradicts this belief? Think of times when it wasn't true.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Create a New Belief", prompt: "Based on all the evidence, write a more balanced belief.", userInput: "", isComplete: false)
            ]
        case .breathing:
            return [
                GuidedExerciseStep(id: UUID(), title: "Inhale", prompt: "Breathe in quietly through your nose for 4 counts", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Hold", prompt: "Hold your breath for 7 counts", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Exhale", prompt: "Exhale completely through your mouth for 8 counts", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Repeat", prompt: "Repeat the cycle 3-4 times. Notice how you feel.", userInput: "", isComplete: false)
            ]
        case .grounding:
            return [
                GuidedExerciseStep(id: UUID(), title: "5 Things You See", prompt: "Look around and name 5 things you can see. Be specific.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "4 Things You Touch", prompt: "Notice 4 things you can physically feel right now.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "3 Things You Hear", prompt: "Listen and name 3 sounds you can hear.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "2 Things You Smell", prompt: "Notice 2 scents in your environment.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "1 Thing You Taste", prompt: "Notice 1 taste in your mouth.", userInput: "", isComplete: false)
            ]
        case .decatastrophizing:
            return [
                GuidedExerciseStep(id: UUID(), title: "The Catastrophe", prompt: "What's the worst-case scenario you're imagining?", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Likelihood Check", prompt: "On a scale of 0-100%, how likely is this to happen?", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Better Outcomes", prompt: "List 3 more likely, less catastrophic outcomes.", userInput: "", isComplete: false),
                GuidedExerciseStep(id: UUID(), title: "Coping Plan", prompt: "If the worst happened, how would you cope?", userInput: "", isComplete: false)
            ]
        default:
            return [
                GuidedExerciseStep(id: UUID(), title: "Begin", prompt: "Take a moment to center yourself. This exercise will guide you step by step.", userInput: "", isComplete: false)
            ]
        }
    }

    private func loadExercises() {
        guard let data = UserDefaults.standard.data(forKey: "axiom.exercises"),
              let saved = try? JSONDecoder().decode([GuidedExercise].self, from: data) else {
            return
        }
        exercises = saved
    }

    private func saveExercises() {
        if let data = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(data, forKey: "axiom.exercises")
        }
    }
}

// MARK: - Exercise Row View

struct ExerciseRowView: View {
    let exercise: GuidedExercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.type.icon)
                .font(.title2)
                .foregroundColor(exercise.isCompleted ? .green : .accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.title)
                        .font(.headline)
                    if exercise.assignedByTherapist {
                        Text("Assigned")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }
                }

                Text(exercise.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if exercise.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("\(exercise.currentStep)/\(exercise.totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    let onSelect: (GuidedExerciseType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Calmers") {
                    ForEach([GuidedExerciseType.breathing, GuidedExerciseType.grounding, GuidedExerciseType.bodyScan] as [GuidedExerciseType]) { type in
                        ExerciseTypeRow(type: type, onSelect: {
                            onSelect(type)
                            dismiss()
                        })
                    }
                }

                Section("Cognitive Exercises") {
                    ForEach([GuidedExerciseType.beliefRestructuring, GuidedExerciseType.decatastrophizing, GuidedExerciseType.probabilityReestimation, GuidedExerciseType.evidenceWeighing] as [GuidedExerciseType]) { type in
                        ExerciseTypeRow(type: type, onSelect: {
                            onSelect(type)
                            dismiss()
                        })
                    }
                }

                Section("Behavioral") {
                    ForEach([GuidedExerciseType.behavioralActivation, GuidedExerciseType.exposureLadder] as [GuidedExerciseType]) { type in
                        ExerciseTypeRow(type: type, onSelect: {
                            onSelect(type)
                            dismiss()
                        })
                    }
                }
            }
            .navigationTitle("Choose Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ExerciseTypeRow: View {
    let type: GuidedExerciseType
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("\(type.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Session View

struct ExerciseSessionView: View {
    let exercise: GuidedExercise
    let onUpdate: (GuidedExercise) -> Void
    let onComplete: (Bool) -> Void

    @State private var currentStepIndex: Int = 0
    @State private var stepInput: String = ""
    @State private var sessionExercise: GuidedExercise

    init(exercise: GuidedExercise, onUpdate: @escaping (GuidedExercise) -> Void, onComplete: @escaping (Bool) -> Void) {
        self.exercise = exercise
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        self._sessionExercise = State(initialValue: exercise)
    }

    private var currentStep: GuidedExerciseStep? {
        guard currentStepIndex < sessionExercise.steps.count else { return nil }
        return sessionExercise.steps[currentStepIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                if let step = currentStep {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(step.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(step.prompt)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if sessionExercise.type == .breathing && currentStepIndex == 0 {
                                breathingGuide
                            } else {
                                TextEditor(text: $stepInput)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding()
                    }
                }

                navigationButtons
            }
            .navigationTitle(sessionExercise.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        onUpdate(sessionExercise)
                        onComplete(false)
                    }
                }
            }
            .onDisappear {
                onUpdate(sessionExercise)
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentStepIndex + 1), total: Double(sessionExercise.totalSteps))
                .tint(.accentColor)

            Text("Step \(currentStepIndex + 1) of \(sessionExercise.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var breathingGuide: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.accentColor.opacity(0.4))
                    .frame(width: 150, height: 150)
                    .animation(
                        currentStepIndex == 0 ? .easeInOut(duration: 4) :
                        currentStepIndex == 1 ? .easeInOut(duration: 7) :
                        .easeInOut(duration: 8),
                        value: currentStepIndex
                    )

                Text(currentStepIndex == 0 ? "4" : currentStepIndex == 1 ? "7" : "8")
                    .font(.system(size: 60, weight: .light, design: .rounded))
            }

            Text(currentStep?.title ?? "")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStepIndex > 0 {
                Button("Previous") {
                    saveCurrentInput()
                    currentStepIndex -= 1
                    loadCurrentInput()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStepIndex == sessionExercise.totalSteps - 1 {
                Button("Complete") {
                    saveCurrentInput()
                    onUpdate(sessionExercise)
                    onComplete(true)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Next") {
                    saveCurrentInput()
                    sessionExercise.steps[currentStepIndex].isComplete = !stepInput.isEmpty
                    currentStepIndex += 1
                    stepInput = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(stepInput.isEmpty && sessionExercise.type != .breathing)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func saveCurrentInput() {
        guard currentStepIndex < sessionExercise.steps.count else { return }
        sessionExercise.steps[currentStepIndex].userInput = stepInput
        sessionExercise.currentStep = currentStepIndex
    }

    private func loadCurrentInput() {
        guard currentStepIndex < sessionExercise.steps.count else { return }
        stepInput = sessionExercise.steps[currentStepIndex].userInput
    }
}
