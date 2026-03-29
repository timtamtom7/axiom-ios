import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showingAddBelief = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain",
            iconColor: Theme.accentPurple,
            title: "Welcome to Axiom",
            subtitle: "Your personal belief audit journal",
            description: "Axiom helps you examine, challenge, and understand the beliefs that shape how you see yourself and the world.",
            gradientColors: [Color(hex: "1a1a2e"), Color(hex: "0a0a0f")]
        ),
        OnboardingPage(
            icon: "doc.text.magnifyingglass",
            iconColor: Theme.accentBlue,
            title: "Record Your Beliefs",
            subtitle: "Write down what you believe",
            description: "Start by capturing a belief you hold about yourself — something like 'I am bad at relationships' or 'I am capable of learning anything.'",
            gradientColors: [Color(hex: "0d1b2a"), Color(hex: "0a0a0f")]
        ),
        OnboardingPage(
            icon: "checkmark.circle",
            iconColor: Theme.accentGreen,
            title: "Gather Evidence",
            subtitle: "Support and challenge each belief",
            description: "Add evidence that supports your belief and evidence that contradicts it. Be honest — the goal is clarity, not confirmation.",
            gradientColors: [Color(hex: "0d2818"), Color(hex: "0a0a0f")]
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColor: Theme.accentGold,
            title: "AI-Powered Insights",
            subtitle: "Let Apple Intelligence help",
            description: "Axiom uses AI to detect thinking patterns, suggest challenges to your beliefs, and help you see your blind spots.",
            gradientColors: [Color(hex: "1a1400"), Color(hex: "0a0a0f")]
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: Theme.accentPurple,
            title: "Track Your Growth",
            subtitle: "Watch beliefs evolve over time",
            description: "See how your beliefs change as you add evidence. Your beliefs aren't fixed — they're updated by experience.",
            gradientColors: [Color(hex: "1a1a2e"), Color(hex: "0a0a0f")]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.7)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, Theme.screenMargin)
                        .padding(.top, Theme.spacingM)
                    }
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 480)

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.accentGold : Theme.textSecondary.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, Theme.spacingL)

                // Action button
                VStack(spacing: Theme.spacingM) {
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(duration: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.headline)
                            .foregroundColor(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGold)
                            .cornerRadius(Theme.cornerRadiusL)
                    }

                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("I'll explore on my own")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, Theme.screenMargin)
                .padding(.bottom, Theme.spacingXL)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let gradientColors: [Color]
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(page.iconColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(page.iconColor)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
            }

            VStack(spacing: Theme.spacingS) {
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundColor(page.iconColor)
                    .textCase(.uppercase)
                    .tracking(2)
                    .fontWeight(.medium)

                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingL)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.screenMargin)
    }
}

// MARK: - Tutorial Overlay Manager

@MainActor
final class TutorialManager: ObservableObject {
    static let shared = TutorialManager()

    @Published var activeOverlay: TutorialOverlay?
    @Published var shownOverlays: Set<String> = []

    private init() {
        loadShownOverlays()
    }

    func shouldShowOverlay(for key: String) -> Bool {
        !shownOverlays.contains(key)
    }

    func markOverlayShown(_ key: String) {
        shownOverlays.insert(key)
        saveShownOverlays()
    }

    func show(_ overlay: TutorialOverlay) {
        activeOverlay = overlay
        markOverlayShown(overlay.id)
    }

    func dismissCurrent() {
        activeOverlay = nil
    }

    private func loadShownOverlays() {
        if let array = UserDefaults.standard.array(forKey: "tutorial_shown_overlays") as? [String] {
            shownOverlays = Set(array)
        }
    }

    private func saveShownOverlays() {
        UserDefaults.standard.set(Array(shownOverlays), forKey: "tutorial_shown_overlays")
    }
}

// MARK: - Tutorial Overlay

struct TutorialOverlay: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let anchorView: AnchorView
    let position: Position

    enum AnchorView: String {
        case addButton = "add_button"
        case beliefCard = "belief_card"
        case stressTestButton = "stress_test_button"
        case evidenceButton = "evidence_button"
        case insightsTab = "insights_tab"
    }

    enum Position {
        case top, bottom, center
    }

    static let defaultTutorials: [TutorialOverlay] = [
        TutorialOverlay(
            id: "first_belief_card",
            title: "Your Belief Card",
            description: "Tap here to view full details, add evidence, and run AI stress tests.",
            icon: "doc.text",
            anchorView: .beliefCard,
            position: .bottom
        ),
        TutorialOverlay(
            id: "add_belief",
            title: "Add a Belief",
            description: "Tap + to record a new belief about yourself.",
            icon: "plus.circle",
            anchorView: .addButton,
            position: .bottom
        ),
        TutorialOverlay(
            id: "stress_test",
            title: "AI Stress Test",
            description: "Let Apple Intelligence challenge your belief with Socratic questions.",
            icon: "brain",
            anchorView: .stressTestButton,
            position: .top
        ),
        TutorialOverlay(
            id: "add_evidence",
            title: "Add Evidence",
            description: "Build a case for and against this belief.",
            icon: "checkmark.circle",
            anchorView: .evidenceButton,
            position: .top
        ),
        TutorialOverlay(
            id: "insights",
            title: "Insights Dashboard",
            description: "Track your streaks, see belief trajectories, and discover patterns.",
            icon: "chart.bar",
            anchorView: .insightsTab,
            position: .top
        )
    ]
}

// MARK: - Tutorial Overlay View

struct TutorialOverlayView: View {
    let overlay: TutorialOverlay
    let onDismiss: () -> Void
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: Theme.spacingM) {
                if overlay.position == .bottom {
                    Spacer()
                }

                VStack(spacing: Theme.spacingM) {
                    Image(systemName: overlay.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Theme.accentGold)

                    Text(overlay.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text(overlay.description)
                        .font(.callout)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        onDismiss()
                    } label: {
                        Text("Got it")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.background)
                            .padding(.horizontal, Theme.spacingXL)
                            .padding(.vertical, Theme.spacingS)
                            .background(Theme.accentGold)
                            .cornerRadius(Theme.cornerRadiusPill)
                    }
                }
                .padding(Theme.spacingL)
                .background(Theme.surface)
                .cornerRadius(Theme.cornerRadiusXL)
                .shadow(color: .black.opacity(0.3), radius: 20)
                .scaleEffect(appearAnimation ? 1 : 0.8)
                .opacity(appearAnimation ? 1 : 0)

                if overlay.position == .top {
                    Spacer()
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, 80)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                appearAnimation = true
            }
        }
    }
}

// MARK: - First Belief Tutorial

struct FirstBeliefCreatedTutorial: View {
    let belief: Belief
    let onDismiss: () -> Void
    let onAddEvidence: () -> Void
    let onStressTest: () -> Void

    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Theme.spacingL) {
                Spacer()

                VStack(spacing: Theme.spacingL) {
                    // Checkmark
                    ZStack {
                        Circle()
                            .fill(Theme.accentGreen.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentGreen)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)

                    VStack(spacing: Theme.spacingS) {
                        Text("First Belief Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text("'\(belief.text.prefix(40))'")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacingM)

                        Text("Now add evidence to test this belief from multiple angles.")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appearAnimation ? 1 : 0)

                    VStack(spacing: Theme.spacingM) {
                        Button(action: onAddEvidence) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Evidence")
                            }
                            .font(.headline)
                            .foregroundColor(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accentGreen)
                            .cornerRadius(Theme.cornerRadiusL)
                        }

                        Button(action: onStressTest) {
                            HStack {
                                Image(systemName: "brain")
                                Text("Run AI Stress Test")
                            }
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(Theme.cornerRadiusL)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusL)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                        }

                        Button(action: onDismiss) {
                            Text("I'll do this later")
                                .font(.callout)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .padding(.horizontal, Theme.spacingL)
                }
                .padding(Theme.spacingL)
                .background(Theme.surface)
                .cornerRadius(Theme.cornerRadiusXL)
                .shadow(color: .black.opacity(0.4), radius: 30)
                .padding(.horizontal, Theme.screenMargin)
                .scaleEffect(appearAnimation ? 1 : 0.85)
                .opacity(appearAnimation ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
}

// MARK: - Onboarding Checker Modifier

struct OnboardingChecker: ViewModifier {
    @ObservedObject var tutorialManager = TutorialManager.shared
    @Binding var hasCompletedOnboarding: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            }

            if let overlay = tutorialManager.activeOverlay {
                TutorialOverlayView(overlay: overlay) {
                    tutorialManager.dismissCurrent()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: tutorialManager.activeOverlay != nil)
    }
}

extension View {
    func withOnboardingCheck(hasCompletedOnboarding: Binding<Bool>) -> some View {
        modifier(OnboardingChecker(hasCompletedOnboarding: hasCompletedOnboarding))
    }
}

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview("Tutorial") {
    ZStack {
        Theme.background.ignoresSafeArea()
        TutorialOverlayView(
            overlay: TutorialOverlay.defaultTutorials[1]
        ) {}
    }
    .preferredColorScheme(.dark)
}
