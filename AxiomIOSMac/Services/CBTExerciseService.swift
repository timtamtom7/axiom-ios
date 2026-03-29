import Foundation

/// R11: Guided CBT exercises for cognitive restructuring
final class CBTExerciseService {
    static let shared = CBTExerciseService()

    private init() {}

    // MARK: - Available Exercises

    enum ExerciseType: String, CaseIterable, Identifiable {
        case cognitiveRestructuring = "Cognitive Restructuring"
        case threeColumnTechnique   = "Three-Column Technique"
        case downwardArrow           = "Downward Arrow"
        case evidenceBurger         = "Evidence Review"
        case behavioralExperiment    = "Behavioral Experiment"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .cognitiveRestructuring: return "Identify and challenge distorted thoughts"
            case .threeColumnTechnique:   return "Automatic thought → distortion → balanced response"
            case .downwardArrow:           return "Drill down to core beliefs"
            case .evidenceBurger:           return "Weigh supporting vs contradicting evidence"
            case .behavioralExperiment:     return "Test beliefs through action"
            }
        }

        var icon: String {
            switch self {
            case .cognitiveRestructuring: return "brain"
            case .threeColumnTechnique:   return "list.number"
            case .downwardArrow:           return "arrow.down.to.line"
            case .evidenceBurger:          return "scale.3d"
            case .behavioralExperiment:     return "flask"
            }
        }
    }

    // MARK: - Guided Exercise Session

    func startExercise(type: ExerciseType, for belief: Belief) -> ExerciseSession {
        let steps = buildSteps(for: type, belief: belief)
        return ExerciseSession(
            id: UUID(),
            type: type,
            beliefId: belief.id,
            beliefText: belief.text,
            steps: steps,
            currentStepIndex: 0,
            startedAt: Date()
        )
    }

    private func buildSteps(for type: ExerciseType, belief: Belief) -> [ExerciseStep] {
        switch type {
        case .cognitiveRestructuring:
            return buildCognitiveRestructuringSteps(for: belief)
        case .threeColumnTechnique:
            return buildThreeColumnSteps(for: belief)
        case .downwardArrow:
            return buildDownwardArrowSteps(for: belief)
        case .evidenceBurger:
            return buildEvidenceBurgerSteps(for: belief)
        case .behavioralExperiment:
            return buildBehavioralExperimentSteps(for: belief)
        }
    }

    // MARK: - Step Builders

    private func buildCognitiveRestructuringSteps(for belief: Belief) -> [ExerciseStep] {
        let analysis = AIBeliefService.shared.analyzeBelief(belief)

        var steps: [ExerciseStep] = []

        // Step 1: Present the belief
        steps.append(ExerciseStep(
            title: "The Belief",
            instruction: "Let's examine this thought: '\(belief.text)'",
            prompt: "Take a moment to really notice this thought. How does it make you feel?",
            promptType: .reflection
        ))

        // Step 2: Identify emotions
        steps.append(ExerciseStep(
            title: "Your Emotional Response",
            instruction: "What emotions does this belief bring up for you?",
            prompt: "Rate the intensity of each emotion (0-100):",
            promptType: .emotionRating,
            suggestions: ["Anxiety", "Sadness", "Anger", "Guilt", "Shame"]
        ))

        // Step 3: Spot distortions
        if !analysis.distortions.isEmpty {
            let distortionNames = analysis.distortions.map { $0.rawValue }.joined(separator: ", ")
            steps.append(ExerciseStep(
                title: "Cognitive Distortions",
                instruction: "I notice some thinking patterns here: \(distortionNames)",
                prompt: "Which of these patterns do you recognize in your thinking?",
                promptType: .multiselect,
                options: analysis.distortions.map { $0.rawValue }
            ))
        } else {
            steps.append(ExerciseStep(
                title: "Thinking Patterns",
                instruction: "Let's look at how you might be filtering reality here.",
                prompt: "Can you find an exception to this belief — a time when it wasn't true?",
                promptType: .reflection
            ))
        }

        // Step 4: Challenge questions
        for (index, question) in analysis.challengeQuestions.prefix(3).enumerated() {
            steps.append(ExerciseStep(
                title: "Challenge #\(index + 1)",
                instruction: question,
                prompt: "Write your reflection:",
                promptType: .freeResponse
            ))
        }

        // Step 5: Alternative belief
        steps.append(ExerciseStep(
            title: "A New Perspective",
            instruction: "Based on your reflections, here's a more balanced view:",
            prompt: "\(analysis.alternativeBelief)\n\nDoes this feel more accurate? Why or why not?",
            promptType: .reflection
        ))

        // Step 6: Commitment
        steps.append(ExerciseStep(
            title: "Moving Forward",
            instruction: "What will you do differently now that you've examined this thought?",
            prompt: "One small action you can take:",
            promptType: .actionCommitment
        ))

        return steps
    }

    private func buildThreeColumnSteps(for belief: Belief) -> [ExerciseStep] {
        var steps: [ExerciseStep] = []

        steps.append(ExerciseStep(
            title: "Automatic Thought",
            instruction: "What thought automatically popped into your mind?",
            prompt: belief.text,
            promptType: .confirmation
        ))

        steps.append(ExerciseStep(
            title: "Cognitive Distortion",
            instruction: "What thinking pattern might be at play?",
            prompt: "Common patterns: All-or-Nothing, Catastrophizing, Mind Reading, Fortune Telling, Emotional Reasoning",
            promptType: .multiselect,
            options: CognitiveDistortion.allCases.map(\.rawValue)
        ))

        steps.append(ExerciseStep(
            title: "Balanced Response",
            instruction: "What's a more balanced, realistic way to view this situation?",
            prompt: "Consider: What evidence supports this alternative? What would I tell a friend?",
            promptType: .freeResponse
        ))

        return steps
    }

    private func buildDownwardArrowSteps(for belief: Belief) -> [ExerciseStep] {
        var steps: [ExerciseStep] = []

        steps.append(ExerciseStep(
            title: "Surface Thought",
            instruction: "Let's start with: '\(belief.text)'",
            prompt: "If this thought were true, what would it mean about you or your situation?",
            promptType: .reflection
        ))

        steps.append(ExerciseStep(
            title: "The Implication",
            instruction: "If that implication were true, what would be even worse about that?",
            prompt: "Continue drilling down: 'And if that's true, then...'",
            promptType: .reflection
        ))

        steps.append(ExerciseStep(
            title: "Core Belief",
            instruction: "What core belief about yourself are you protecting or reinforcing?",
            prompt: "Examples: I'm not good enough, I'm unlovable, I'm a failure, I'm helpless",
            promptType: .coreBeliefIdentification,
            suggestions: ["Not Good Enough", "Unlovable", "Failure", "Helpless", "Burden to Others"]
        ))

        steps.append(ExerciseStep(
            title: "Evidence Check",
            instruction: "Let's examine the evidence for this core belief.",
            prompt: "What's one piece of evidence that contradicts this core belief?",
            promptType: .freeResponse
        ))

        return steps
    }

    private func buildEvidenceBurgerSteps(for belief: Belief) -> [ExerciseStep] {
        var steps: [ExerciseStep] = []

        steps.append(ExerciseStep(
            title: "Supporting Evidence",
            instruction: "Let's weigh the evidence for: '\(belief.text)'",
            prompt: "List the evidence that supports this belief:",
            promptType: .evidenceList,
            existingEvidence: belief.evidenceItems.filter { $0.type == .support }.map { $0.text }
        ))

        steps.append(ExerciseStep(
            title: "Contradicting Evidence",
            instruction: "Now let's look at the other side.",
            prompt: "List the evidence that contradicts this belief:",
            promptType: .evidenceList,
            existingEvidence: belief.evidenceItems.filter { $0.type == .contradict }.map { $0.text }
        ))

        steps.append(ExerciseStep(
            title: "Balanced Verdict",
            instruction: "Based on all the evidence, how would you rate this belief now?",
            prompt: "Consider: Is the supporting evidence strong? Is contradicting evidence being dismissed?",
            promptType: .scoreUpdate
        ))

        return steps
    }

    private func buildBehavioralExperimentSteps(for belief: Belief) -> [ExerciseStep] {
        var steps: [ExerciseStep] = []

        steps.append(ExerciseStep(
            title: "The Prediction",
            instruction: "What do you believe will happen? '\(belief.text)'",
            prompt: "Be specific: What exactly do you expect to happen?",
            promptType: .reflection
        ))

        steps.append(ExerciseStep(
            title: "Design the Test",
            instruction: "How could you test this belief in real life?",
            prompt: "What small action or experiment would give you data?",
            promptType: .freeResponse
        ))

        steps.append(ExerciseStep(
            title: "Alternative Outcome",
            instruction: "What's a more likely outcome based on evidence?",
            prompt: "What actually happens most of the time in situations like this?",
            promptType: .reflection
        ))

        steps.append(ExerciseStep(
            title: "Commitment",
            instruction: "When and how will you run this experiment?",
            prompt: "Set a specific time and note what you'll observe:",
            promptType: .actionCommitment
        ))

        return steps
    }

    // MARK: - Session Progress

    func advanceStep(in session: inout ExerciseSession) -> Bool {
        guard session.currentStepIndex < session.steps.count - 1 else { return false }
        session.currentStepIndex += 1
        return true
    }

    func recordResponse(in session: inout ExerciseSession, response: String) {
        let currentStep = session.currentStep
        var responses = session.stepResponses
        responses[currentStep.title] = response
        session.stepResponses = responses
    }

    func completeSession(_ session: ExerciseSession) -> ExerciseCompletion {
        let summary = generateCompletionSummary(for: session)
        return ExerciseCompletion(
            session: session,
            completedAt: Date(),
            summary: summary
        )
    }

    private func generateCompletionSummary(for session: ExerciseSession) -> String {
        let analysis = AIBeliefService.shared.analyzeBelief(
            Belief(id: session.beliefId, text: session.beliefText)
        )

        if analysis.distortions.isEmpty {
            return "You completed the exercise for '\(session.beliefText)'. No major distortions were detected — keep monitoring this belief."
        }

        let distortions = analysis.distortions.map { $0.rawValue }.joined(separator: ", ")
        return "Well done! You worked through '\(session.beliefText)'. Detected thinking patterns: \(distortions)."
    }
}

// MARK: - Exercise Types

struct ExerciseSession: Identifiable {
    let id: UUID
    let type: CBTExerciseService.ExerciseType
    let beliefId: UUID
    let beliefText: String
    let steps: [ExerciseStep]
    var currentStepIndex: Int
    let startedAt: Date
    var stepResponses: [String: String] = [:]

    var currentStep: ExerciseStep { steps[currentStepIndex] }
    var isComplete: Bool { currentStepIndex >= steps.count - 1 }
    var progress: Double { Double(currentStepIndex + 1) / Double(steps.count) }
    var remainingSteps: Int { steps.count - currentStepIndex - 1 }
}

struct ExerciseStep: Identifiable {
    let id = UUID()
    let title: String
    let instruction: String
    let prompt: String
    let promptType: ExercisePromptType
    var options: [String] = []
    var suggestions: [String] = []
    var existingEvidence: [String] = []
}

enum ExercisePromptType {
    case reflection
    case emotionRating
    case multiselect
    case freeResponse
    case confirmation
    case coreBeliefIdentification
    case evidenceList
    case scoreUpdate
    case actionCommitment
}

struct ExerciseCompletion: Identifiable {
    let id = UUID()
    let session: ExerciseSession
    let completedAt: Date
    let summary: String
}
